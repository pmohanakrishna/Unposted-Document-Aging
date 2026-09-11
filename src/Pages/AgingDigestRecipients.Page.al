namespace Mohana.UnpostedDocumentAging;

page 50202 "Aging Digest Recipients"
{
    ApplicationArea = All;
    Caption = 'Aging Digest Recipients';
    PageType = ListPart;
    SourceTable = "Aging Digest Recipient";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Recipients)
            {
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the user who receives the digest.';
                }
                field("Email Address"; Rec."Email Address")
                {
                    ToolTip = 'Specifies the address the digest is sent to. Leave blank to use the email address on the user card.';
                }
                field("Salesperson Filter"; Rec."Salesperson Filter")
                {
                    ToolTip = 'Specifies which salespeople the rows are limited to. Leave blank for all.';
                }
                field("Send Own Rows Only"; Rec."Send Own Rows Only")
                {
                    ToolTip = 'Specifies whether the recipient only receives rows for the salesperson code on their user setup.';
                }
            }
        }
    }
}
