namespace Mohana.UnpostedDocumentAging;

using Microsoft.CRM.Team;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Security.User;

permissionset 50200 "Unposted Doc Aging"
{
    Assignable = true;
    Caption = 'Unposted Document Aging';

    Permissions =
        tabledata "Unposted Aging Buffer" = RIMD,
        tabledata "Unposted Aging Setup" = RIMD,
        tabledata "Aging Digest Recipient" = RIMD,
        tabledata "Sales Header" = r,
        tabledata "Sales Line" = r,
        tabledata "Purchase Header" = r,
        tabledata "Purchase Line" = r,
        tabledata "Salesperson/Purchaser" = r,
        tabledata "User Setup" = r,
        table "Unposted Aging Buffer" = X,
        table "Unposted Aging Setup" = X,
        table "Aging Digest Recipient" = X,
        page "Unposted Document Aging" = X,
        page "Unposted Aging Setup" = X,
        page "Aging Digest Recipients" = X,
        codeunit "Unposted Aging Mgt." = X,
        codeunit "Unposted Aging Digest" = X,
        codeunit "Unposted Aging Install" = X;
}
