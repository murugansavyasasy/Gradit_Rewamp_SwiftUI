//
//  MockExamService.swift
//  Gradit
//
//  In-memory exam-application data used in DEBUG, previews and tests. Mirrors examAplication.pdf.
//

import Foundation

final class MockExamService: ExamServiceProtocol {
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func children() async throws -> [FacultyChild] {
        try await Task.sleep(for: latency)
        return [
            .init(id: "aarav", name: "Aarav R.", classLabel: "B.E. CSE · Sem 5 A"),
            .init(id: "diya", name: "Diya R.", classLabel: "B.Tech IT · Sem 3 B"),
        ]
    }

    func examApplications(childID: String?) async throws -> ExamBundle {
        try await Task.sleep(for: latency)
        if childID == "diya" {
            return ExamBundle(alert: nil, items: [
                .init(id: "e-ese-diya", title: "End Semester Examination, Nov 2026", type: .regular,
                      semesterLine: "Sem 3 · Academic year 2026–27", datesLine: "Opens 01 Oct · Last date 09 Oct",
                      daysLeftText: nil, closed: false, status: .approved, amountText: "₹1,000"),
            ])
        }
        return ExamBundle(
            alert: ExamAlert(title: "End Semester Examination: 2 days left",
                             message: "Fee not paid yet. Pay on the web portal by Fri 09 Oct.", examID: "e-ese"),
            items: [
                .init(id: "e-arrear", title: "Arrear Examination, Nov 2026", type: .arrear,
                      semesterLine: "Sem 3 · Academic year 2026–27", datesLine: "Opens 03 Oct · Last date 12 Oct",
                      daysLeftText: "5 days left", closed: false, status: .notApplied, amountText: "₹650"),
                .init(id: "e-reval", title: "Revaluation – Sem 4 results, Apr 2026", type: .revaluation,
                      semesterLine: "Sem 4 · Academic year 2025–26", datesLine: "Opens today · Last date 14 Oct",
                      daysLeftText: "7 days left", closed: false, status: .notApplied, amountText: "₹750 / paper"),
                .init(id: "e-ese", title: "End Semester Examination, Nov 2026", type: .regular,
                      semesterLine: "Sem 5 · Academic year 2026–27", datesLine: "Opens 01 Oct · Last date 09 Oct",
                      daysLeftText: "2 days left", closed: false, status: .paymentPending, amountText: "₹1,150"),
                .init(id: "e-supp", title: "Supplementary Examination, Oct 2026", type: .supplementary,
                      semesterLine: "Sem 4 · Academic year 2025–26", datesLine: "Opens 21 Sep · Last date 05 Oct",
                      daysLeftText: nil, closed: false, status: .applied, amountText: "₹550"),
                .init(id: "e-reval3", title: "Revaluation – Sem 3 results, Nov 2025", type: .revaluation,
                      semesterLine: "Sem 3 · Academic year 2025–26", datesLine: "Opens 12 Jan · Last date 19 Jan",
                      daysLeftText: nil, closed: true, status: .rejected, amountText: "₹750 / paper"),
                .init(id: "e-supp-jul", title: "Supplementary Examination, Jul 2026", type: .supplementary,
                      semesterLine: "Sem 4 · Academic year 2025–26", datesLine: "Opens 01 Jul · Last date 10 Jul 2026",
                      daysLeftText: nil, closed: true, status: .closed, amountText: "₹550"),
                .init(id: "e-arrear-apr", title: "Arrear Examination, Apr 2026", type: .arrear,
                      semesterLine: "Sem 3 · Academic year 2025–26", datesLine: "Opens 02 Mar · Last date 16 Mar 2026",
                      daysLeftText: nil, closed: true, status: .closed, amountText: "₹450"),
            ])
    }

    func examApplicationDetail(childID: String?, id: String) async throws -> ExamApplicationDetail {
        try await Task.sleep(for: latency)
        switch id {
        case "e-ese": // Regular · payment pending
            return ExamApplicationDetail(
                id: id, title: "End Semester Examination, Nov 2026", type: .regular,
                semesterLine: "Sem 5 · Academic year 2026–27", status: .paymentPending,
                appliedOnText: "Applied on the web on Mon 05 Oct, 07:42 PM",
                banner: ExamStatusBanner(kind: .paymentPending, title: "Payment pending · ₹1,150",
                    message: "The application is filled in, but the fee isn't paid yet. Pay on the web portal by Fri 09 Oct. After that a late fee of ₹500 applies until Wed 14 Oct.",
                    bullets: [], actionTitle: nil, contactText: nil),
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Thu 01 Oct", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Fri 09 Oct", note: "2 days left", state: .current),
                    ExamKeyDate(id: "k3", label: "Late fee last date · ₹500 extra", value: "Wed 14 Oct", note: nil, state: .future),
                    ExamKeyDate(id: "k4", label: "Exam starts", value: "Mon 23 Nov", note: nil, state: .future),
                ],
                feeLines: [
                    ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250"),
                    ExamFeeLine(id: "f2", label: "Per-paper fee · 5 papers × ₹180", amount: "₹900"),
                ],
                feeTotal: "₹1,150", paymentNote: "Not paid yet · Pay on the web portal by Fri 09 Oct.", paymentPaid: false,
                papersHeading: "Papers in this application", papers: Self.sem5Papers)
        case "e-reval": // Revaluation · not applied
            return ExamApplicationDetail(
                id: id, title: "Revaluation – Sem 4 results, Apr 2026", type: .revaluation,
                semesterLine: "Sem 4 · Academic year 2025–26", status: .notApplied, appliedOnText: nil, banner: nil,
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Wed 07 Oct (today)", note: "Today", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Wed 14 Oct", note: "7 days left", state: .current),
                    ExamKeyDate(id: "k3", label: "Revised results", value: "Results by Mon 09 Nov", note: nil, state: .future),
                ],
                feeLines: [ExamFeeLine(id: "f1", label: "Revaluation fee · per paper", amount: "₹750")],
                feeTotal: "₹750", paymentNote: "Not paid yet · Pay on the web portal after you fill in the application.", paymentPaid: false,
                papersHeading: "Papers you can apply for", papers: [
                    ExamPaper(id: "p1", code: "CS3452", name: "Theory of Computation"),
                    ExamPaper(id: "p2", code: "CS3491", name: "Artificial Intelligence"),
                ])
        case "e-supp": // Supplementary · applied + paid
            return ExamApplicationDetail(
                id: id, title: "Supplementary Examination, Oct 2026", type: .supplementary,
                semesterLine: "Sem 4 · Academic year 2025–26", status: .applied,
                appliedOnText: "Applied on the web on Tue 29 Sep, 06:10 PM", banner: nil,
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Mon 21 Sep", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Mon 05 Oct", note: "Closed", state: .done),
                    ExamKeyDate(id: "k3", label: "Exam starts", value: "Thu 22 Oct", note: nil, state: .future),
                ],
                feeLines: [
                    ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250"),
                    ExamFeeLine(id: "f2", label: "Per-paper fee · 1 paper × ₹300", amount: "₹300"),
                ],
                feeTotal: "₹550",
                paymentNote: "Paid on Tue 29 Sep, 06:15 PM\nReference UCE-EXM-26-48213\nUPI · Paid by Rajesh Sharma", paymentPaid: true,
                papersHeading: "Papers in this application", papers: [ExamPaper(id: "p1", code: "CS3401", name: "Algorithms")])
        case "e-ese-diya", "e-approved": // Regular · approved
            return ExamApplicationDetail(
                id: id, title: "End Semester Examination, Nov 2026", type: .regular,
                semesterLine: "Sem 3 · Academic year 2026–27", status: .approved,
                appliedOnText: "Applied on the web on Fri 02 Oct, 08:12 PM",
                banner: ExamStatusBanner(kind: .approved, title: "Approved · next steps",
                    message: "", bullets: [
                        "Hall ticket available from Mon 16 Nov, 10:00 AM",
                        "Exams start Mon 23 Nov · forenoon session 10:00 AM – 01:00 PM",
                        "Check your seat in the Exams screen two days before each exam",
                    ], actionTitle: "Go to Exams and hall ticket", contactText: nil),
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Thu 01 Oct", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Fri 09 Oct", note: "You have already applied", state: .done),
                    ExamKeyDate(id: "k3", label: "Late fee last date · ₹500 extra", value: "Wed 14 Oct", note: nil, state: .future),
                    ExamKeyDate(id: "k4", label: "Exam starts", value: "Mon 23 Nov", note: nil, state: .future),
                ],
                feeLines: [ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250"),
                           ExamFeeLine(id: "f2", label: "Per-paper fee · 5 papers × ₹150", amount: "₹750")],
                feeTotal: "₹1,000", paymentNote: "Paid on Fri 02 Oct, 08:15 PM · UPI", paymentPaid: true,
                papersHeading: "Papers in this application", papers: Self.sem5Papers)
        case "e-reval3": // Revaluation · rejected
            return ExamApplicationDetail(
                id: id, title: "Revaluation – Sem 3 results, Nov 2025", type: .revaluation,
                semesterLine: "Sem 3 · Academic year 2025–26", status: .rejected,
                appliedOnText: "Applied on the web on Fri 16 Jan 2026",
                banner: ExamStatusBanner(kind: .rejected, title: "Rejected by the exam cell",
                    message: "Revaluation needs the photocopy of the answer script first. No photocopy request was found for MA3354, so this application could not be processed. The fee of ₹750 has been refunded.",
                    bullets: [], actionTitle: "Call exam cell · 044 2235 7140",
                    contactText: "Mr. Balasubramanian R., Controller's office, Block A\nexamcell@ucechennai.ac.in · Mon – Sat, 10:00 AM – 04:00 PM"),
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Mon 12 Jan 2026", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Mon 19 Jan 2026", note: "Closed", state: .done),
                ],
                feeLines: [ExamFeeLine(id: "f1", label: "Revaluation fee · per paper", amount: "₹750")],
                feeTotal: "₹750 (refunded)", paymentNote: "Refunded to the original payment method.", paymentPaid: true,
                papersHeading: "Papers in this application", papers: [ExamPaper(id: "p1", code: "MA3354", name: "Discrete Mathematics")])
        case "e-noteligible":
            return ExamApplicationDetail(
                id: id, title: "End Semester Examination, Nov 2026", type: .regular,
                semesterLine: "Sem 5 · Academic year 2026–27", status: .notEligible, appliedOnText: nil,
                banner: ExamStatusBanner(kind: .notEligible, title: "Not eligible to apply",
                    message: "Attendance in Computer Networks is 71%. The minimum is 75%. You can apply only if the Principal approves condonation.\n\nSubmit a condonation request with a medical certificate at the department office by Fri 09 Oct. The exam cell will update this screen once it is approved.",
                    bullets: [], actionTitle: nil, contactText: nil),
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Thu 01 Oct", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Fri 09 Oct", note: nil, state: .current),
                    ExamKeyDate(id: "k4", label: "Exam starts", value: "Mon 23 Nov", note: nil, state: .future),
                ],
                feeLines: [ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250")],
                feeTotal: "₹1,150", paymentNote: "You can pay once the application is approved.", paymentPaid: false,
                papersHeading: "Papers you can apply for", papers: Self.sem5Papers)
        case "e-supp-jul": // Closed
            return ExamApplicationDetail(
                id: id, title: "Supplementary Examination, Jul 2026", type: .supplementary,
                semesterLine: "Sem 4 · Academic year 2025–26", status: .closed, appliedOnText: nil,
                banner: ExamStatusBanner(kind: .closed, title: "Application closed",
                    message: "The window closed on Fri 10 Jul 2026 and no application was made. If you still need to write these papers, apply in the next supplementary window. The exam cell posts it here and on the notice board.",
                    bullets: [], actionTitle: nil, contactText: nil),
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Wed 01 Jul 2026", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Fri 10 Jul 2026", note: "Closed", state: .done),
                    ExamKeyDate(id: "k3", label: "Exam starts", value: "Mon 27 Jul 2026", note: nil, state: .future),
                ],
                feeLines: [ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250"),
                           ExamFeeLine(id: "f2", label: "Per-paper fee", amount: "₹300")],
                feeTotal: "₹550", paymentNote: "No payment was made.", paymentPaid: false,
                papersHeading: "Papers you could have applied for", papers: [ExamPaper(id: "p1", code: "CS3401", name: "Algorithms")])
        default: // Arrear · not applied
            return ExamApplicationDetail(
                id: id, title: "Arrear Examination, Nov 2026", type: .arrear,
                semesterLine: "Sem 3 · Academic year 2026–27", status: .notApplied, appliedOnText: nil, banner: nil,
                keyDates: [
                    ExamKeyDate(id: "k1", label: "Application opens", value: "Sat 03 Oct", note: "Done", state: .done),
                    ExamKeyDate(id: "k2", label: "Last date", value: "Mon 12 Oct", note: "5 days left", state: .current),
                    ExamKeyDate(id: "k3", label: "Exam starts", value: "Tue 24 Nov", note: nil, state: .future),
                ],
                feeLines: [
                    ExamFeeLine(id: "f1", label: "Exam application fee", amount: "₹250"),
                    ExamFeeLine(id: "f2", label: "Per-paper fee · 2 papers × ₹200", amount: "₹400"),
                ],
                feeTotal: "₹650", paymentNote: "Not paid yet · Pay on the web portal after you fill in the application.", paymentPaid: false,
                papersHeading: "Papers in this application", papers: [
                    ExamPaper(id: "p1", code: "MA3354", name: "Discrete Mathematics"),
                    ExamPaper(id: "p2", code: "CS3351", name: "Digital Principles and Computer Organization"),
                ])
        }
    }

    private static let sem5Papers: [ExamPaper] = [
        ExamPaper(id: "p1", code: "CS3492", name: "Database Management Systems"),
        ExamPaper(id: "p2", code: "CS3451", name: "Operating Systems"),
        ExamPaper(id: "p3", code: "CS3591", name: "Computer Networks"),
        ExamPaper(id: "p4", code: "CS3452", name: "Theory of Computation"),
        ExamPaper(id: "p5", code: "GE3451", name: "Environmental Sciences"),
    ]
}
