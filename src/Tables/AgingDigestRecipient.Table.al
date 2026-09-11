namespace Mohana.UnpostedDocumentAging;

using System.Security.AccessControl;
using System.Security.User;

table 50202 "Aging Digest Recipient"
{
    Caption = 'Aging Digest Recipient';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if Rec."Email Address" = '' then
                    Rec."Email Address" := ResolveUserEmail(Rec."User ID");
            end;
        }
        field(11; "Email Address"; Text[80])
        {
            Caption = 'Email Address';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = EMail;
        }
        field(20; "Salesperson Filter"; Code[250])
        {
            Caption = 'Salesperson Filter';
            DataClassification = CustomerContent;
        }
        field(30; "Send Own Rows Only"; Boolean)
        {
            Caption = 'Send Own Rows Only';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "User ID", "Email Address")
        {
        }
    }

    trigger OnInsert()
    var
        DigestRecipient: Record "Aging Digest Recipient";
    begin
        if Rec."Line No." <> 0 then
            exit;
        if DigestRecipient.FindLast() then
            Rec."Line No." := DigestRecipient."Line No." + 10000
        else
            Rec."Line No." := 10000;
    end;

    /// <summary>
    /// Resolves the salesperson filter for this recipient. Returns false when the recipient should be skipped.
    /// </summary>
    procedure TryGetSalespersonFilter(var SalespersonFilter: Text): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        SalespersonFilter := '';
        if Rec."Salesperson Filter" <> '' then begin
            SalespersonFilter := Rec."Salesperson Filter";
            exit(true);
        end;
        if not Rec."Send Own Rows Only" then
            exit(true);
        if not UserSetup.Get(Rec."User ID") then
            exit(false);
        if UserSetup."Salespers./Purch. Code" = '' then
            exit(false);
        SalespersonFilter := UserSetup."Salespers./Purch. Code";
        exit(true);
    end;

    procedure GetEmailAddress(): Text[80]
    begin
        if Rec."Email Address" <> '' then
            exit(Rec."Email Address");
        exit(ResolveUserEmail(Rec."User ID"));
    end;

    local procedure ResolveUserEmail(UserName: Code[50]): Text[80]
    var
        User: Record User;
    begin
        if UserName = '' then
            exit('');
        User.SetLoadFields("Contact Email", "Authentication Email");
        User.SetRange("User Name", UserName);
        if not User.FindFirst() then
            exit('');
        if User."Contact Email" <> '' then
            exit(CopyStr(User."Contact Email", 1, 80));
        exit(CopyStr(User."Authentication Email", 1, 80));
    end;
}
