# Loan API and UI audit

The loan integration was traced through `ApiService`, GetX controllers and
bindings, route definitions, loan views, and the request/response tests. No
OpenAPI schema, Postman collection, or other backend contract document was
found in the repository. Request shapes and response examples below are
therefore verified against the existing service and tested v1 integrations;
unobserved server fields and endpoint behavior are not inferred.

| # | Operation | Verified endpoint and contract | UI journey and state |
|---|---|---|---|
| 1 | Create fixed-rate loan contract | `POST /api/v1/loans`. Existing controller sends `loan_type`, name/lender, sanctioned/principal amounts, `currency`, annual rate, tenure, first due date, repayment account, interest category, and notes. The test verifies a success envelope with `data.uuid`. | Loans → **Create loan** → create-contract form. Confirmation explicitly states that creating the contract does not disburse funds. |
| 2 | Disburse loan | `POST /api/v1/loans/{loan_uuid}/disbursements`. Body: `gross_amount`, `processing_fee`, `fee_category_uuid`, `disbursement_date`, `receiving_account_uuid`. Existing request test verifies the path and body. No response-calculated net amount contract was found. | Active loan details → **Record Disbursement** → disbursement form and confirmation. Detail/schedule/payment reads refresh after success. |
| 3 | List loans | `GET /api/v1/loans?page={page}&per_page={perPage}`. Tested response has `data.items` and `data.pagination`. | Loans screen → **Loans** section; paginated cards open loan detail. Cards render only fields present in the list response. |
| 4 | Loan detail and summary | `GET /api/v1/loans/{loan_uuid}`. Tested response is `data` containing the loan record (including optional names, amounts, rate, tenure, dates, status, and currency). | Tap a loan card or an installment row to open the readable Loan details screen. Missing values are not synthesized; structured fields are not dumped as JSON. |
| 5 | Schedule | `GET /api/v1/loans/{loan_uuid}/schedule`. Tested response contains schedule `items`, with fields such as installment number, due date, installment/principal/interest amounts, and status. | Loan details → **View Repayment Schedule** or the Repayment schedule section. The endpoint is verified for schedule items, not for schedule-version history. |
| 6 | Partial EMI payment | `POST /api/v1/loans/{loan_uuid}/payments`. Body: `amount`, `payment_date`, `source_account_uuid`, `installment_uuid`, and optional `reference`/`description`; request and validation behavior are covered by tests. | Active loan details → **Record EMI Payment**, or a **Pay this installment** button on each unpaid schedule row. Row action carries its installment UUID into the payment form. Confirmation precedes submission; success refreshes loan, schedule, and payment history. |
| 7 | Payment history | `GET /api/v1/loans/{loan_uuid}/payments?page={page}&per_page={perPage}`. Tested response has `data.items` and pagination; rendered fields include amount, date, account, and reference when present. | Loan details → **View Payment History** or Payment history section, with pagination and retry states. |
| 8 | Principal prepayment | `POST /api/v1/loans/{loan_uuid}/prepayments`. Body is verified by the test: `amount`, `payment_date`, `source_account_uuid`, `reference`, and `description`. Positive amount, account, and description are validated in the existing controller. | Active loan details → **Principal Prepayment** → dedicated form, optional verified outstanding-principal context, confirmation, duplicate-submit protection, and detail/schedule/payment refresh after success. |
| 9 | Disbursement history | No GET service method, endpoint constant, route, request/response fixture, or documentation exists in this repository. Only the disbursement POST endpoint is defined. | Not exposed: the GET contract and response fields are unavailable. No path is inferred from the POST route. |
| 10 | Upcoming installments | `GET /api/v1/loan-installments/upcoming`. Tested response has `data.items`; available due date, amount, and loan name are rendered. | Loans → **Upcoming** section; rows open the related loan detail when the response provides its loan UUID. |
| 11 | Overdue installments | `GET /api/v1/loan-installments/overdue`. Tested response has `data.items`; available due date, amount, and overdue days are rendered. | Loans → **Overdue** section; rows open the related loan detail when the response provides its loan UUID. |
| 12 | Portfolio/loan summary | `GET /api/v1/loans/summary?from_date={YYYY-MM-DD}&to_date={YYYY-MM-DD}`. Existing tests verify date filters and summary data including principal, repaid, outstanding, and loan count. | Loans screen → dated **Loan summary** panel. Only metrics present in the response are shown. |

## Contract blockers

- The requested **GET disbursement history** operation has no implementation or
  contract evidence in this repository. It cannot be added without an exact
  backend route and response schema.
- The existing schedule route returns a tested schedule-item collection, but
  no schedule-version endpoint or version metadata is defined or tested. The
  UI therefore shows the verified repayment schedule only and does not claim
  to provide historical versions.
- The service and tests verify gross amount and processing fee for
  disbursement, but not a server-calculated net amount. The UI confirms the
  gross and fee and asks users to verify net proceeds with the lender instead
  of assuming an amount.
