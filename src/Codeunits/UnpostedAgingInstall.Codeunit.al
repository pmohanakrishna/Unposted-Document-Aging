namespace Mohana.UnpostedDocumentAging;

codeunit 50202 "Unposted Aging Install"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        AgingSetup: Record "Unposted Aging Setup";
    begin
        AgingSetup.InsertIfNotExists();
    end;
}
