# Analytical methodology and checks

## Unit of analysis
- A **loan-level defaulted-record share** divides the number of loans marked `Defaulted` by the number of loans in a segment.
- A **defaulted original-principal share** divides the sum of original `loan_amount` for Defaulted loans by all original loan amounts in the same segment.
- A **customer-level default prevalence** divides the number of customers with at least one Defaulted loan by customers in the borrowing-frequency group.
- Zero-loan customers are included with `LEFT JOIN`; their loan-level defaulted rate is undefined (`NULL`), not 0%.

## Segments
- Monthly income: <K10,000; K10,000–<K20,000; K20,000–<K40,000; ≥K40,000.
- Original loan size: <K50,000; K50,000–<K100,000; K100,000–<K200,000; ≥K200,000.
- Interest-rate bands: <15%; 15%–<22%; 22%–<29%; ≥29%.
- Borrowing-frequency groups: 0; 1; 2; or 3+ loans per customer.

## SQL pipeline
1. Inspect tables and record counts (`01_` and `02_` scripts).
2. Calculate overall loan statuses and branch metrics (`03_` to `05_`).
3. Join loans to customers to add income groups (`12A_`, `12B_`).
4. Apply loan-size and interest-rate/product segmentation (`13_`, `14A_`, `14B_`).
5. Aggregate to customer before analysing borrowing frequency (`15A_`, `15B_`).
6. Run duplicate, orphan, missingness, invalid-value, reconciliation and assertion checks (`16A_`–`16E_`).
7. Produce final branch and headline analyses (`17_`).

## Checks observed on the original local run
- 16A: no duplicate loan IDs.
- 16B: no loans linked to nonexistent customers.
- 16C: no invalid or missing records among the six tested fields/conditions.
- 16D: four headline reconciliation totals matched, `totals_reconcile = true`.
- 16E: all seven assertions returned `PASS`.

## Limitations
The dataset is synthetic and its default status is partly assigned based on loan-to-income relationships by the generator. Descriptive defaulted-record shares do not establish causation or generalise to the Zambian banking system. No original-principal measure should be labelled outstanding exposure, loan loss, regulatory NPL, or probability of future default. The aggregate results are saved as the observed reference snapshot, but the original raw-level snapshot is not included.
