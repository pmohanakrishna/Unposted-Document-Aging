namespace Mohana.UnpostedDocumentAging;

using Microsoft.Utilities;

table 50200 "Unposted Aging Buffer"
{
    Caption = 'Unposted Aging Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Source; Enum "Aging Doc Source")
        {
            Caption = 'Source';
            DataClassification = CustomerContent;
        }
        field(3; "Document Type"; Integer)
        {
            Caption = 'Document Type Ordinal';
            DataClassification = CustomerContent;
        }
        field(4; "Document Type Text"; Text[30])
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(10; "Partner No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
            DataClassification = CustomerContent;
        }
        field(11; "Partner Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
            DataClassification = CustomerContent;
        }
        field(20; "Base Date"; Date)
        {
            Caption = 'Base Date';
            DataClassification = CustomerContent;
        }
        field(21; "Days Old"; Integer)
        {
            Caption = 'Days Old';
            DataClassification = CustomerContent;
        }
        field(22; "Aging Band"; Enum "Aging Band")
        {
            Caption = 'Aging Band';
            DataClassification = CustomerContent;
        }
        field(30; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
        }
        field(31; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(40; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
        }
        field(41; "Salesperson Name"; Text[100])
        {
            Caption = 'Salesperson Name';
            DataClassification = CustomerContent;
        }
        field(42; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50; Status; Text[30])
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(51; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped/Received';
            DataClassification = CustomerContent;
        }
        field(60; "Source Record Id"; RecordId)
        {
            Caption = 'Source Record Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Band; "Aging Band", "Days Old")
        {
        }
        key(Salesperson; "Salesperson Code", "Aging Band")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document Type Text", "Document No.", "Partner Name")
        {
        }
    }

    procedure ShowDocument()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if Rec."Source Record Id".TableNo() = 0 then
            exit;
        if not RecRef.Get(Rec."Source Record Id") then
            exit;
        PageManagement.PageRun(RecRef);
    end;
}
