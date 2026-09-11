namespace Mohana.UnpostedDocumentAging;

page 50200 "Unposted Document Aging"
{
    ApplicationArea = All;
    Caption = 'Unposted Document Aging';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Unposted Aging Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AnalysisModeEnabled = true;

    layout
    {
        area(Content)
        {
            repeater(Documents)
            {
                field("Aging Band"; Rec."Aging Band")
                {
                    ToolTip = 'Specifies why the document is considered stale.';
                    StyleExpr = RowStyleTxt;
                }
                field("Days Old"; Rec."Days Old")
                {
                    ToolTip = 'Specifies how many days have passed since the base date.';
                    StyleExpr = RowStyleTxt;
                }
                field(Source; Rec.Source)
                {
                    ToolTip = 'Specifies whether the document is a sales or a purchase document.';
                }
                field("Document Type Text"; Rec."Document Type Text")
                {
                    ToolTip = 'Specifies the document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the document number. Choose the value to open the document.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowDocument();
                    end;
                }
                field("Partner No."; Rec."Partner No.")
                {
                    ToolTip = 'Specifies the customer or vendor number on the document.';
                }
                field("Partner Name"; Rec."Partner Name")
                {
                    ToolTip = 'Specifies the customer or vendor name on the document.';
                }
                field("Base Date"; Rec."Base Date")
                {
                    ToolTip = 'Specifies the date that the age is measured from.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the document amount including VAT, converted to the local currency.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency of the document.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ToolTip = 'Specifies the salesperson or purchaser on the document.';
                }
                field("Salesperson Name"; Rec."Salesperson Name")
                {
                    ToolTip = 'Specifies the name of the salesperson or purchaser on the document.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ToolTip = 'Specifies the user who is responsible for the document.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Completely Shipped"; Rec."Completely Shipped")
                {
                    ToolTip = 'Specifies whether everything on the order has been shipped or received.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Rebuild the list from the current documents.';

                trigger OnAction()
                begin
                    BuildRows();
                    CurrPage.Update(false);
                end;
            }
            action(OpenDocument)
            {
                Caption = 'Open Document';
                Image = Document;
                Scope = Repeater;
                ToolTip = 'Open the document behind the selected line.';

                trigger OnAction()
                begin
                    Rec.ShowDocument();
                end;
            }
            action(OpenSetup)
            {
                Caption = 'Setup';
                Image = Setup;
                RunObject = page "Unposted Aging Setup";
                ToolTip = 'Open the aging thresholds and digest settings.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh)
                {
                }
                actionref(OpenDocument_Promoted; OpenDocument)
                {
                }
                actionref(OpenSetup_Promoted; OpenSetup)
                {
                }
            }
        }
    }

    var
        RowStyleTxt: Text;

    trigger OnOpenPage()
    begin
        BuildRows();
    end;

    trigger OnAfterGetRecord()
    begin
        RowStyleTxt := '';
        if Rec."Aging Band" in [Rec."Aging Band"::"Shipped Not Invoiced", Rec."Aging Band"::"Quote Expired"] then
            RowStyleTxt := 'Unfavorable';
    end;

    local procedure BuildRows()
    var
        UnpostedAgingMgt: Codeunit "Unposted Aging Mgt.";
    begin
        UnpostedAgingMgt.BuildBuffer(Rec);
        if Rec.FindFirst() then;
    end;
}
