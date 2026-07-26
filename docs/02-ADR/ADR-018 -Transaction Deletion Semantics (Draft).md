ADR-018 — Transaction Deletion Semantics (Draft)
القرار

في Wafferly V4، Delete يعني إزالة المعاملة من الحقيقة المالية (Financial Truth)، وليس إنشاء Reverse Transaction أو Void Transaction.

النتيجة:

يتم حذف الـ Transaction من TransactionPort.
يتم حذف أو إعادة إسقاط (re-project) الـ Ledger بما يتوافق مع المعمارية الحالية.
لا يتم إنشاء Transaction تعويضية.
لا يتم الاحتفاظ بـ Audit Trail في هذه المرحلة.
السبب
Wafferly هو Personal Finance Application وليس ERP.
المستخدم يتوقع أن حذف معاملة أُدخلت بالخطأ يجعلها كأنها لم تكن.
دعم Audit وReversal يمكن إضافته مستقبلًا دون كسر الـ Pipeline.
خارج النطاق
Undo.
Audit Log.
Reverse Journals.
Soft Delete.