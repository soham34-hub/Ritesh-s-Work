public class QueueableAggregator {

    // All CPR items collected across all queueables in the transaction
    public static List<CasePromotionCprBatchQueueable.CprDTO> cprJobs =
        new List<CasePromotionCprBatchQueueable.CprDTO>();

    // Make sure we only enqueue CPR once per transaction
    public static Boolean enqueued = false;

    // Add a CPR job safely to the collection
    public static void add(CasePromotionCprBatchQueueable.CprDTO dto) {
        cprJobs.add(dto);
    }
}