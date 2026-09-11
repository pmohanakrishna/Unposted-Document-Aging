namespace Mohana.UnpostedDocumentAging;

using Microsoft.CRM.Team;
using System.Email;

codeunit 50201 "Unposted Aging Digest"
{
    Access = Public;

    trigger OnRun()
    var
        AgingSetup: Record "Unposted Aging Setup";
    begin
        AgingSetup.GetSetup();
        if not AgingSetup."Digest Enabled" then
            exit;
        RunDigest();
    end;

    var
        FailureBuilder: TextBuilder;
        SubjectLbl: Label 'Unposted documents needing attention (%1)', Comment = '%1 = number of documents';
        SalespersonGreetingLbl: Label 'Hello %1, the following documents are ageing and assigned to you.', Comment = '%1 = salesperson name';
        RecipientGreetingLbl: Label 'The following unposted documents are ageing.';
        AndMoreLbl: Label 'and %1 more.', Comment = '%1 = number of rows not shown';
        NoEmailErr: Label 'No email address could be resolved.';
        InvalidEmailErr: Label 'The email address is not valid.';
        FailureEntryTok: Label '%1: %2; ', Locked = true;
        BandHeaderLbl: Label 'Aging Band';
        DaysOldHeaderLbl: Label 'Days Old';
        DocumentHeaderLbl: Label 'Document';
        PartnerHeaderLbl: Label 'Customer/Vendor';
        AmountHeaderLbl: Label 'Amount (LCY)';

    procedure RunDigest()
    var
        TempAgingBuffer: Record "Unposted Aging Buffer" temporary;
        AgingSetup: Record "Unposted Aging Setup";
        UnpostedAgingMgt: Codeunit "Unposted Aging Mgt.";
    begin
        AgingSetup.InsertIfNotExists();
        AgingSetup.Get('');
        Clear(FailureBuilder);

        UnpostedAgingMgt.BuildBuffer(TempAgingBuffer);
        if not TempAgingBuffer.IsEmpty() then begin
            if AgingSetup."Send Salesperson Digests" then
                SendSalespersonDigests(TempAgingBuffer);
            SendRecipientDigests(TempAgingBuffer);
        end;

        AgingSetup."Last Digest Run" := CurrentDateTime();
        AgingSetup."Last Digest Errors" := CopyStr(FailureBuilder.ToText(), 1, MaxStrLen(AgingSetup."Last Digest Errors"));
        AgingSetup.Modify(true);
    end;

    local procedure SendSalespersonDigests(var AgingBuffer: Record "Unposted Aging Buffer" temporary)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonCodes: List of [Code[20]];
        SalespersonCode: Code[20];
    begin
        AgingBuffer.Reset();
        AgingBuffer.SetFilter("Salesperson Code", '<>%1', '');
        if AgingBuffer.FindSet() then
            repeat
                if not SalespersonCodes.Contains(AgingBuffer."Salesperson Code") then
                    SalespersonCodes.Add(AgingBuffer."Salesperson Code");
            until AgingBuffer.Next() = 0;
        AgingBuffer.Reset();

        foreach SalespersonCode in SalespersonCodes do begin
            SalespersonPurchaser.SetLoadFields(Name, "E-Mail");
            if not SalespersonPurchaser.Get(SalespersonCode) then
                LogFailure(SalespersonCode, NoEmailErr)
            else begin
                AgingBuffer.SetRange("Salesperson Code", SalespersonCode);
                SendDigest(AgingBuffer, SalespersonPurchaser."E-Mail", StrSubstNo(SalespersonGreetingLbl, SalespersonPurchaser.Name), SalespersonCode);
                AgingBuffer.SetRange("Salesperson Code");
            end;
        end;
    end;

    local procedure SendRecipientDigests(var AgingBuffer: Record "Unposted Aging Buffer" temporary)
    var
        DigestRecipient: Record "Aging Digest Recipient";
        SalespersonFilter: Text;
    begin
        if not DigestRecipient.FindSet() then
            exit;
        repeat
            if DigestRecipient.TryGetSalespersonFilter(SalespersonFilter) then begin
                AgingBuffer.Reset();
                if SalespersonFilter <> '' then
                    AgingBuffer.SetFilter("Salesperson Code", SalespersonFilter);
                SendDigest(AgingBuffer, DigestRecipient.GetEmailAddress(), RecipientGreetingLbl, DigestRecipient."User ID");
            end;
        until DigestRecipient.Next() = 0;
        AgingBuffer.Reset();
    end;

    local procedure SendDigest(var AgingBuffer: Record "Unposted Aging Buffer" temporary; EmailAddress: Text[80]; Greeting: Text; Identifier: Text)
    var
        Body: Text;
        Subject: Text;
    begin
        if AgingBuffer.IsEmpty() then
            exit;
        if EmailAddress = '' then begin
            LogFailure(Identifier, NoEmailErr);
            exit;
        end;
        if StrPos(EmailAddress, '@') = 0 then begin
            LogFailure(Identifier, InvalidEmailErr);
            exit;
        end;

        Subject := StrSubstNo(SubjectLbl, AgingBuffer.Count());
        Body := BuildHtmlBody(AgingBuffer, Greeting);
        if not TrySendEmail(EmailAddress, Subject, Body) then
            LogFailure(Identifier, GetLastErrorText());
    end;

    [TryFunction]
    local procedure TrySendEmail(EmailAddress: Text[80]; Subject: Text; Body: Text)
    var
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        Recipients: List of [Text];
        SendFailedErr: Label 'The email could not be queued for sending.';
    begin
        Recipients.Add(EmailAddress);
        EmailMessage.Create(Recipients, Subject, Body, true);
        if not Email.Send(EmailMessage, Enum::"Email Scenario"::"Unposted Aging Digest") then
            Error(SendFailedErr);
    end;

    local procedure BuildHtmlBody(var AgingBuffer: Record "Unposted Aging Buffer" temporary; Greeting: Text): Text
    var
        AgingBand: Enum "Aging Band";
        HtmlBuilder: TextBuilder;
        BandCount: Integer;
        BandOrdinal: Integer;
        RowCount: Integer;
        TotalRows: Integer;
    begin
        TotalRows := AgingBuffer.Count();

        HtmlBuilder.Append('<div style="font-family:Segoe UI,Arial,sans-serif;font-size:13px;color:#201f1e;">');
        HtmlBuilder.Append('<p>' + EncodeHtml(Greeting) + '</p><ul>');
        foreach BandOrdinal in Enum::"Aging Band".Ordinals() do begin
            AgingBand := Enum::"Aging Band".FromInteger(BandOrdinal);
            AgingBuffer.SetRange("Aging Band", AgingBand);
            BandCount := AgingBuffer.Count();
            if BandCount > 0 then
                HtmlBuilder.Append('<li><b>' + EncodeHtml(Format(AgingBand)) + '</b>: ' + Format(BandCount) + '</li>');
        end;
        AgingBuffer.SetRange("Aging Band");
        HtmlBuilder.Append('</ul>');

        HtmlBuilder.Append('<table style="border-collapse:collapse;font-size:12px;" cellpadding="6"><tr style="background-color:#f3f2f1;text-align:left;">');
        HtmlBuilder.Append(HeaderCell(BandHeaderLbl) + HeaderCell(DaysOldHeaderLbl) + HeaderCell(DocumentHeaderLbl) + HeaderCell(PartnerHeaderLbl) + HeaderCell(AmountHeaderLbl));
        HtmlBuilder.Append('</tr>');

        AgingBuffer.SetCurrentKey("Aging Band", "Days Old");
        if AgingBuffer.FindSet() then
            repeat
                RowCount += 1;
                HtmlBuilder.Append('<tr>');
                HtmlBuilder.Append(BodyCell(Format(AgingBuffer."Aging Band")));
                HtmlBuilder.Append(BodyCell(Format(AgingBuffer."Days Old")));
                HtmlBuilder.Append(BodyCell(AgingBuffer."Document Type Text" + ' ' + AgingBuffer."Document No."));
                HtmlBuilder.Append(BodyCell(AgingBuffer."Partner Name"));
                HtmlBuilder.Append(BodyCell(Format(AgingBuffer."Amount (LCY)", 0, '<Precision,2:2><Standard Format,0>')));
                HtmlBuilder.Append('</tr>');
            until (AgingBuffer.Next() = 0) or (RowCount >= MaxEmailRows());
        HtmlBuilder.Append('</table>');

        if TotalRows > RowCount then
            HtmlBuilder.Append('<p>' + StrSubstNo(AndMoreLbl, TotalRows - RowCount) + '</p>');
        HtmlBuilder.Append('</div>');
        exit(HtmlBuilder.ToText());
    end;

    local procedure HeaderCell(Value: Text): Text
    begin
        exit('<th style="border:1px solid #edebe9;">' + EncodeHtml(Value) + '</th>');
    end;

    local procedure BodyCell(Value: Text): Text
    begin
        exit('<td style="border:1px solid #edebe9;">' + EncodeHtml(Value) + '</td>');
    end;

    local procedure EncodeHtml(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        exit(Value.Replace('"', '&quot;'));
    end;

    local procedure LogFailure(Identifier: Text; FailureText: Text)
    begin
        if StrLen(FailureBuilder.ToText()) > 250 then
            exit;
        FailureBuilder.Append(StrSubstNo(FailureEntryTok, Identifier, FailureText));
    end;

    local procedure MaxEmailRows(): Integer
    begin
        exit(50);
    end;
}
