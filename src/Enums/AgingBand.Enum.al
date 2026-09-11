namespace Mohana.UnpostedDocumentAging;

/// <summary>
/// Ordinals are ordered by how actionable the band is, so sorting on the enum surfaces the money first.
/// </summary>
enum 50201 "Aging Band"
{
    Extensible = true;
    Caption = 'Aging Band';

    value(0; "Shipped Not Invoiced")
    {
        Caption = 'Shipped Not Invoiced';
    }
    value(1; "Quote Expired")
    {
        Caption = 'Quote Expired';
    }
    value(2; "Invoice Unposted")
    {
        Caption = 'Invoice Unposted';
    }
    value(3; "Order Stale")
    {
        Caption = 'Order Stale';
    }
    value(4; "Quote Stale")
    {
        Caption = 'Quote Stale';
    }
    value(5; Other)
    {
        Caption = 'Other';
    }
}
