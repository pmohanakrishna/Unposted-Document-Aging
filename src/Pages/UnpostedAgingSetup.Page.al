namespace Mohana.UnpostedDocumentAging;

using System.Threading;

page 50201 "Unposted Aging Setup"
{
    ApplicationArea = All;
    Caption = 'Unposted Aging Setup';
    PageType = Card;
    UsageCategory = Administration;
    SourceTable = "Unposted Aging Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Thresholds)
            {
                Caption = 'Thresholds';

                field("Quote Threshold Days"; Rec."Quote Threshold Days")
                {
                    ToolTip = 'Specifies how many days a quote must be old before it appears in the list.';
                }
                field("Order Threshold Days"; Rec."Order Threshold Days")
                {
                    ToolTip = 'Specifies how many days an order must be old before it appears in the list.';
                }
                field("Invoice Threshold Days"; Rec."Invoice Threshold Days")
                {
                    ToolTip = 'Specifies how many days an unposted invoice must be old before it appears in the list.';
                }
                field("Age By"; Rec."Age By")
                {
                    ToolTip = 'Specifies whether age is measured from the document date or from the date the record was created.';
                }
            }
            group(Scope)
            {
                Caption = 'Scope';

                field("Include Purchase"; Rec."Include Purchase")
                {
                    ToolTip = 'Specifies whether purchase documents are included alongside sales documents.';
                }
                field("Calculate Amounts"; Rec."Calculate Amounts")
                {
                    ToolTip = 'Specifies whether document amounts are calculated. Turn this off on large databases to speed up the list.';
                }
            }
            group(Digest)
            {
                Caption = 'Digest';

                field("Digest Enabled"; Rec."Digest Enabled")
                {
                    ToolTip = 'Specifies whether the scheduled email digest is sent.';
                }
                field("Send Salesperson Digests"; Rec."Send Salesperson Digests")
                {
                    ToolTip = 'Specifies whether every salesperson with stale documents receives a digest containing only their own rows.';
                }
                field("Last Digest Run"; Rec."Last Digest Run")
                {
                    ToolTip = 'Specifies when the digest last ran.';
                }
                field("Last Digest Errors"; Rec."Last Digest Errors")
                {
                    ToolTip = 'Specifies the errors reported by the last digest run, if any.';
                    MultiLine = true;
                }
            }
            part(Recipients; "Aging Digest Recipients")
            {
                Caption = 'Digest Recipients';
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunDigestNow)
            {
                Caption = 'Send Digest Now';
                Image = Email;
                ToolTip = 'Run the digest immediately using the current settings.';

                trigger OnAction()
                var
                    UnpostedAgingDigest: Codeunit "Unposted Aging Digest";
                begin
                    UnpostedAgingDigest.RunDigest();
                    CurrPage.Update(false);
                    Message(DigestCompletedMsg);
                end;
            }
            action(CreateJobQueueEntry)
            {
                Caption = 'Create Job Queue Entry';
                Image = JobListSetup;
                ToolTip = 'Create a recurring job queue entry that sends the digest on weekday mornings.';

                trigger OnAction()
                begin
                    CreateDigestJobQueueEntry();
                end;
            }
            action(OpenAgingList)
            {
                Caption = 'Unposted Document Aging';
                Image = List;
                RunObject = page "Unposted Document Aging";
                ToolTip = 'Open the aging list.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RunDigestNow_Promoted; RunDigestNow)
                {
                }
                actionref(CreateJobQueueEntry_Promoted; CreateJobQueueEntry)
                {
                }
                actionref(OpenAgingList_Promoted; OpenAgingList)
                {
                }
            }
        }
    }

    var
        DigestCompletedMsg: Label 'The digest run has finished. Check Last Digest Errors for any failures.';
        JobQueueCreatedMsg: Label 'A job queue entry was created. Review it before setting the status to Ready.';
        JobQueueExistsMsg: Label 'A job queue entry for the digest already exists.';
        JobQueueDescriptionTxt: Label 'Unposted document aging digest';

    trigger OnOpenPage()
    var
        AgingSetup: Record "Unposted Aging Setup";
    begin
        AgingSetup.InsertIfNotExists();
        Rec.Get('');
    end;

    local procedure CreateDigestJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Unposted Aging Digest");
        if not JobQueueEntry.IsEmpty() then begin
            Message(JobQueueExistsMsg);
            exit;
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Unposted Aging Digest";
        JobQueueEntry.Description := CopyStr(JobQueueDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Starting Time" := 070000T;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(true);
        Message(JobQueueCreatedMsg);
    end;
}
