namespace Mohana.UnpostedDocumentAging;

enum 50200 "Aging Doc Source"
{
    Extensible = true;
    Caption = 'Aging Document Source';

    value(0; Sales)
    {
        Caption = 'Sales';
    }
    value(1; Purchase)
    {
        Caption = 'Purchase';
    }
}
