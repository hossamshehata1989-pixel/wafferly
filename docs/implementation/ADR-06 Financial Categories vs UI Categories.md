ADR-006 — Financial Categories vs UI Categories
UI Category
        │
        ▼
Financial Category
        │
        ▼
Ledger Resolver
        │
        ▼
Ledger Account

القواعد:

UI Categories يمكن أن تتغير.
SubCategories يمكن أن تزيد أو تنقص.
Dynamic Categories لا تؤثر على Financial Truth.
الـ Ledger لا تعتمد على الـ UI.
الـ Financial Engine تستقبل Financial Category فقط.
الـ Resolver هو المسؤول عن تحويلها إلى Ledger Account.