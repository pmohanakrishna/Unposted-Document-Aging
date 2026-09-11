namespace Mohana.UnpostedDocumentAging;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 50200 "Unposted Aging Mgt."
{
    Access = Public;

    var
        SalespersonNames: Dictionary of [Code[20], Text[100]];
        LastEntryNo: Integer;
        CutoffFormulaTok: Label '<-%1D>', Locked = true;

    procedure BuildBuffer(var AgingBuffer: Record "Unposted Aging Buffer" temporary)
    begin
        Build(AgingBuffer, '');
    end;

    procedure BuildBufferForSalesperson(var AgingBuffer: Record "Unposted Aging Buffer" temporary; SalespersonCode: Code[20])
    begin
        Build(AgingBuffer, SalespersonCode);
    end;

    local procedure Build(var AgingBuffer: Record "Unposted Aging Buffer" temporary; SalespersonCode: Code[20])
    var
        AgingSetup: Record "Unposted Aging Setup";
    begin
        AgingBuffer.Reset();
        AgingBuffer.DeleteAll();
        LastEntryNo := 0;
        Clear(SalespersonNames);
        AgingSetup.GetSetup();

        AddSalesDocuments(AgingBuffer, AgingSetup, "Sales Document Type"::Quote, AgingSetup."Quote Threshold Days", SalespersonCode);
        AddSalesDocuments(AgingBuffer, AgingSetup, "Sales Document Type"::Order, AgingSetup."Order Threshold Days", SalespersonCode);
        AddSalesDocuments(AgingBuffer, AgingSetup, "Sales Document Type"::Invoice, AgingSetup."Invoice Threshold Days", SalespersonCode);

        if AgingSetup."Include Purchase" then begin
            AddPurchaseDocuments(AgingBuffer, AgingSetup, "Purchase Document Type"::Quote, AgingSetup."Quote Threshold Days", SalespersonCode);
            AddPurchaseDocuments(AgingBuffer, AgingSetup, "Purchase Document Type"::Order, AgingSetup."Order Threshold Days", SalespersonCode);
            AddPurchaseDocuments(AgingBuffer, AgingSetup, "Purchase Document Type"::Invoice, AgingSetup."Invoice Threshold Days", SalespersonCode);
        end;

        AgingBuffer.Reset();
        AgingBuffer.SetCurrentKey("Aging Band", "Days Old");
    end;

    local procedure AddSalesDocuments(var AgingBuffer: Record "Unposted Aging Buffer" temporary; var AgingSetup: Record "Unposted Aging Setup"; DocumentType: Enum "Sales Document Type"; ThresholdDays: Integer; SalespersonCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
        CutoffDate: Date;
    begin
        CutoffDate := CalcCutoffDate(ThresholdDays);
        SalesHeader.SetLoadFields("Document Type", "No.", "Sell-to Customer No.", "Sell-to Customer Name", "Document Date",
            "Salesperson Code", "Assigned User ID", Status, "Completely Shipped", "Quote Valid Until Date",
            "Currency Code", "Currency Factor", "Amount Including VAT");
        SalesHeader.SetRange("Document Type", DocumentType);
        if SalespersonCode <> '' then
            SalesHeader.SetRange("Salesperson Code", SalespersonCode);
        if AgingSetup."Age By" = AgingSetup."Age By"::Created then
            SalesHeader.SetFilter(SystemCreatedAt, '<%1', CreateDateTime(CutoffDate, 0T))
        else
            SalesHeader.SetFilter("Document Date", '<%1', CutoffDate);

        if SalesHeader.FindSet() then
            repeat
                InsertSalesRow(AgingBuffer, AgingSetup, SalesHeader);
            until SalesHeader.Next() = 0;
    end;

    local procedure InsertSalesRow(var AgingBuffer: Record "Unposted Aging Buffer" temporary; var AgingSetup: Record "Unposted Aging Setup"; var SalesHeader: Record "Sales Header")
    var
        BaseDate: Date;
    begin
        BaseDate := BaseDateFor(AgingSetup, SalesHeader."Document Date", SalesHeader.SystemCreatedAt);

        LastEntryNo += 1;
        AgingBuffer.Init();
        AgingBuffer."Entry No." := LastEntryNo;
        AgingBuffer.Source := AgingBuffer.Source::Sales;
        AgingBuffer."Document Type" := SalesHeader."Document Type".AsInteger();
        AgingBuffer."Document Type Text" := CopyStr(Format(SalesHeader."Document Type"), 1, MaxStrLen(AgingBuffer."Document Type Text"));
        AgingBuffer."Document No." := SalesHeader."No.";
        AgingBuffer."Partner No." := SalesHeader."Sell-to Customer No.";
        AgingBuffer."Partner Name" := SalesHeader."Sell-to Customer Name";
        AgingBuffer."Base Date" := BaseDate;
        AgingBuffer."Days Old" := DaysOld(BaseDate);
        AgingBuffer."Aging Band" := SalesBand(SalesHeader);
        AgingBuffer."Currency Code" := SalesHeader."Currency Code";
        AgingBuffer."Salesperson Code" := SalesHeader."Salesperson Code";
        AgingBuffer."Salesperson Name" := SalespersonName(SalesHeader."Salesperson Code");
        AgingBuffer."Assigned User ID" := SalesHeader."Assigned User ID";
        AgingBuffer.Status := CopyStr(Format(SalesHeader.Status), 1, MaxStrLen(AgingBuffer.Status));
        AgingBuffer."Completely Shipped" := SalesHeader."Completely Shipped";
        AgingBuffer."Source Record Id" := SalesHeader.RecordId();
        if AgingSetup."Calculate Amounts" then begin
            SalesHeader.CalcFields("Amount Including VAT");
            AgingBuffer."Amount (LCY)" := ToLCY(SalesHeader."Amount Including VAT", SalesHeader."Currency Code", SalesHeader."Currency Factor", BaseDate);
        end;
        AgingBuffer.Insert();
    end;

    local procedure SalesBand(var SalesHeader: Record "Sales Header"): Enum "Aging Band"
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote:
                if (SalesHeader."Quote Valid Until Date" <> 0D) and (SalesHeader."Quote Valid Until Date" < WorkDate()) then
                    exit(Enum::"Aging Band"::"Quote Expired")
                else
                    exit(Enum::"Aging Band"::"Quote Stale");
            SalesHeader."Document Type"::Order:
                if SalesHeader."Completely Shipped" or SalesOrderHasShipment(SalesHeader."No.") then
                    exit(Enum::"Aging Band"::"Shipped Not Invoiced")
                else
                    exit(Enum::"Aging Band"::"Order Stale");
            SalesHeader."Document Type"::Invoice:
                exit(Enum::"Aging Band"::"Invoice Unposted");
        end;
        exit(Enum::"Aging Band"::Other);
    end;

    local procedure SalesOrderHasShipment(DocumentNo: Code[20]): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetFilter("Quantity Shipped", '>%1', 0);
        exit(not SalesLine.IsEmpty());
    end;

    local procedure AddPurchaseDocuments(var AgingBuffer: Record "Unposted Aging Buffer" temporary; var AgingSetup: Record "Unposted Aging Setup"; DocumentType: Enum "Purchase Document Type"; ThresholdDays: Integer; PurchaserCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        CutoffDate: Date;
    begin
        CutoffDate := CalcCutoffDate(ThresholdDays);
        PurchaseHeader.SetLoadFields("Document Type", "No.", "Buy-from Vendor No.", "Buy-from Vendor Name", "Document Date",
            "Purchaser Code", "Assigned User ID", Status, "Completely Received",
            "Currency Code", "Currency Factor", "Amount Including VAT");
        PurchaseHeader.SetRange("Document Type", DocumentType);
        if PurchaserCode <> '' then
            PurchaseHeader.SetRange("Purchaser Code", PurchaserCode);
        if AgingSetup."Age By" = AgingSetup."Age By"::Created then
            PurchaseHeader.SetFilter(SystemCreatedAt, '<%1', CreateDateTime(CutoffDate, 0T))
        else
            PurchaseHeader.SetFilter("Document Date", '<%1', CutoffDate);

        if PurchaseHeader.FindSet() then
            repeat
                InsertPurchaseRow(AgingBuffer, AgingSetup, PurchaseHeader);
            until PurchaseHeader.Next() = 0;
    end;

    local procedure InsertPurchaseRow(var AgingBuffer: Record "Unposted Aging Buffer" temporary; var AgingSetup: Record "Unposted Aging Setup"; var PurchaseHeader: Record "Purchase Header")
    var
        BaseDate: Date;
    begin
        BaseDate := BaseDateFor(AgingSetup, PurchaseHeader."Document Date", PurchaseHeader.SystemCreatedAt);

        LastEntryNo += 1;
        AgingBuffer.Init();
        AgingBuffer."Entry No." := LastEntryNo;
        AgingBuffer.Source := AgingBuffer.Source::Purchase;
        AgingBuffer."Document Type" := PurchaseHeader."Document Type".AsInteger();
        AgingBuffer."Document Type Text" := CopyStr(Format(PurchaseHeader."Document Type"), 1, MaxStrLen(AgingBuffer."Document Type Text"));
        AgingBuffer."Document No." := PurchaseHeader."No.";
        AgingBuffer."Partner No." := PurchaseHeader."Buy-from Vendor No.";
        AgingBuffer."Partner Name" := PurchaseHeader."Buy-from Vendor Name";
        AgingBuffer."Base Date" := BaseDate;
        AgingBuffer."Days Old" := DaysOld(BaseDate);
        AgingBuffer."Aging Band" := PurchaseBand(PurchaseHeader);
        AgingBuffer."Currency Code" := PurchaseHeader."Currency Code";
        AgingBuffer."Salesperson Code" := PurchaseHeader."Purchaser Code";
        AgingBuffer."Salesperson Name" := SalespersonName(PurchaseHeader."Purchaser Code");
        AgingBuffer."Assigned User ID" := PurchaseHeader."Assigned User ID";
        AgingBuffer.Status := CopyStr(Format(PurchaseHeader.Status), 1, MaxStrLen(AgingBuffer.Status));
        AgingBuffer."Completely Shipped" := PurchaseHeader."Completely Received";
        AgingBuffer."Source Record Id" := PurchaseHeader.RecordId();
        if AgingSetup."Calculate Amounts" then begin
            PurchaseHeader.CalcFields("Amount Including VAT");
            AgingBuffer."Amount (LCY)" := ToLCY(PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Code", PurchaseHeader."Currency Factor", BaseDate);
        end;
        AgingBuffer.Insert();
    end;

    local procedure PurchaseBand(var PurchaseHeader: Record "Purchase Header"): Enum "Aging Band"
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                exit(Enum::"Aging Band"::"Quote Stale");
            PurchaseHeader."Document Type"::Order:
                if PurchaseHeader."Completely Received" or PurchaseOrderHasReceipt(PurchaseHeader."No.") then
                    exit(Enum::"Aging Band"::"Shipped Not Invoiced")
                else
                    exit(Enum::"Aging Band"::"Order Stale");
            PurchaseHeader."Document Type"::Invoice:
                exit(Enum::"Aging Band"::"Invoice Unposted");
        end;
        exit(Enum::"Aging Band"::Other);
    end;

    local procedure PurchaseOrderHasReceipt(DocumentNo: Code[20]): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetFilter("Quantity Received", '>%1', 0);
        exit(not PurchaseLine.IsEmpty());
    end;

    local procedure BaseDateFor(var AgingSetup: Record "Unposted Aging Setup"; DocumentDate: Date; CreatedAt: DateTime): Date
    begin
        if AgingSetup."Age By" = AgingSetup."Age By"::Created then
            exit(DT2Date(CreatedAt));
        exit(DocumentDate);
    end;

    local procedure DaysOld(BaseDate: Date): Integer
    begin
        if BaseDate = 0D then
            exit(0);
        exit(WorkDate() - BaseDate);
    end;

    local procedure CalcCutoffDate(ThresholdDays: Integer): Date
    begin
        if ThresholdDays <= 0 then
            exit(CalcDate('<+1D>', WorkDate()));
        exit(CalcDate(StrSubstNo(CutoffFormulaTok, ThresholdDays), WorkDate()));
    end;

    local procedure ToLCY(Amount: Decimal; CurrencyCode: Code[10]; CurrencyFactor: Decimal; BaseDate: Date): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ConversionDate: Date;
    begin
        if (Amount = 0) or (CurrencyCode = '') then
            exit(Amount);
        ConversionDate := BaseDate;
        if ConversionDate = 0D then
            ConversionDate := WorkDate();
        exit(Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(ConversionDate, CurrencyCode, Amount, CurrencyFactor)));
    end;

    local procedure SalespersonName(SalespersonCode: Code[20]): Text[100]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ResolvedName: Text[100];
    begin
        if SalespersonCode = '' then
            exit('');
        if SalespersonNames.Get(SalespersonCode, ResolvedName) then
            exit(ResolvedName);
        SalespersonPurchaser.SetLoadFields(Name);
        if SalespersonPurchaser.Get(SalespersonCode) then
            ResolvedName := SalespersonPurchaser.Name;
        SalespersonNames.Add(SalespersonCode, ResolvedName);
        exit(ResolvedName);
    end;
}
