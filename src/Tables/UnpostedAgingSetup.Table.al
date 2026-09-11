namespace Mohana.UnpostedDocumentAging;

table 50201 "Unposted Aging Setup"
{
    Caption = 'Unposted Aging Setup';
    DataClassification = CustomerContent;
    DataPerCompany = true;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Quote Threshold Days"; Integer)
        {
            Caption = 'Quote Threshold Days';
            DataClassification = CustomerContent;
            InitValue = 30;
            MinValue = 0;
        }
        field(11; "Order Threshold Days"; Integer)
        {
            Caption = 'Order Threshold Days';
            DataClassification = CustomerContent;
            InitValue = 14;
            MinValue = 0;
        }
        field(12; "Invoice Threshold Days"; Integer)
        {
            Caption = 'Invoice Threshold Days';
            DataClassification = CustomerContent;
            InitValue = 7;
            MinValue = 0;
        }
        field(20; "Include Purchase"; Boolean)
        {
            Caption = 'Include Purchase Documents';
            DataClassification = CustomerContent;
        }
        field(30; "Age By"; Enum "Aging Date Basis")
        {
            Caption = 'Age By';
            DataClassification = CustomerContent;
        }
        field(40; "Calculate Amounts"; Boolean)
        {
            Caption = 'Calculate Amounts';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(50; "Digest Enabled"; Boolean)
        {
            Caption = 'Digest Enabled';
            DataClassification = CustomerContent;
        }
        field(51; "Last Digest Run"; DateTime)
        {
            Caption = 'Last Digest Run';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(52; "Send Salesperson Digests"; Boolean)
        {
            Caption = 'Send Per-Salesperson Digests';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(53; "Last Digest Errors"; Text[250])
        {
            Caption = 'Last Digest Errors';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if Rec.Get('') then
            exit;
        Rec.Init();
        Rec."Primary Key" := '';
    end;

    procedure InsertIfNotExists()
    var
        Setup: Record "Unposted Aging Setup";
    begin
        if Setup.Get('') then
            exit;
        Setup.Init();
        Setup."Primary Key" := '';
        Setup.Insert(true);
    end;
}
