//
//  ExamApplicationDetailView.swift
//  Gradit
//
//  Student / parent exam application detail: status banner, key-dates timeline,
//  fee breakdown, papers. Design: examAplication.pdf p9–16.
//

import SwiftUI

struct ExamApplicationDetailView: View {
    let examID: String
    let childID: String?

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExamDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            AssignmentTopBar(title: String(localized: "Exam application"),
                             subtitle: model?.detail?.semesterLine, showsBack: true) { dismiss() }
            if let model, let detail = model.detail {
                content(detail)
            } else if let model, model.errorMessage != nil {
                ErrorStateView(message: model.errorMessage ?? "") { model.reload() }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil { model = ExamDetailViewModel(childID: childID, examID: examID, service: dependencies.examService) }
            await model?.load()
        }
    }

    private func content(_ d: ExamApplicationDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard(d)
                if let banner = d.banner { bannerCard(banner) }
                keyDatesCard(d)
                feeCard(d)
                papersCard(d)
            }
            .padding(16).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func headerCard(_ d: ExamApplicationDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(d.title).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                StatusBadge(text: d.type.title, tone: d.type.tone, weight: .bold)
                Text(d.semesterLine).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            StatusBadge(text: d.status.title, tone: d.status.tone, systemImage: d.status.systemImage, weight: .heavy)
            if let applied = d.appliedOnText {
                Text(applied).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Banner

    @ViewBuilder
    private func bannerCard(_ b: ExamStatusBanner) -> some View {
        let (fg, bg): (Color, Color) = switch b.kind {
        case .paymentPending: (Theme.Colors.amber800, Theme.Colors.warningBackground)
        case .approved: (Theme.Colors.green700, Theme.Colors.green50)
        case .rejected, .notEligible: (Theme.Colors.destructive, Theme.Colors.errorBackground)
        case .closed: (Theme.Colors.ink700, Theme.Colors.surfaceMuted)
        }
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: bannerIcon(b.kind)).font(.system(size: 14, weight: .bold))
                Text(b.title).font(AppFont.jakarta(15, .heavy))
            }
            .foregroundStyle(fg)
            if !b.message.isEmpty {
                Text(b.message).font(AppFont.jakarta(13)).foregroundStyle(fg).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(b.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(fg)
                    Text(bullet).font(AppFont.jakarta(13)).foregroundStyle(fg).fixedSize(horizontal: false, vertical: true)
                }
            }
            if let contact = b.contactText {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Need help? Contact the exam cell").font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    Text(contact).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink700).fixedSize(horizontal: false, vertical: true)
                }
                .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Theme.Colors.white, in: .rect(cornerRadius: 10))
            }
            if let action = b.actionTitle {
                Button {} label: {
                    Label(action, systemImage: b.kind == .approved ? "arrow.right" : "phone.fill")
                        .font(AppFont.jakarta(15, .bold))
                        .foregroundStyle(b.kind == .approved ? Theme.Colors.white : Theme.Colors.destructive)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(b.kind == .approved ? AnyShapeStyle(Theme.Colors.green600) : AnyShapeStyle(Color.clear), in: .rect(cornerRadius: 12))
                        .overlay { if b.kind != .approved { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.destructive) } }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(fg.opacity(0.25)))
    }

    private func bannerIcon(_ kind: ExamBannerKind) -> String {
        switch kind {
        case .paymentPending: "indianrupeesign.circle.fill"
        case .approved: "checkmark.seal.fill"
        case .rejected: "exclamationmark.circle.fill"
        case .closed: "clock.fill"
        case .notEligible: "nosign"
        }
    }

    // MARK: - Key dates

    private func keyDatesCard(_ d: ExamApplicationDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Key dates").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900).padding(.bottom, 12)
            ForEach(Array(d.keyDates.enumerated()), id: \.element.id) { index, date in
                timelineRow(date, isLast: index == d.keyDates.count - 1)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    private func timelineRow(_ date: ExamKeyDate, isLast: Bool) -> some View {
        let dotColor: Color = switch date.state {
        case .done: Theme.Colors.green600
        case .current: Theme.Colors.blue600
        case .future: Theme.Colors.ink300
        }
        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    if date.state == .done {
                        Circle().fill(dotColor).frame(width: 14, height: 14)
                    } else {
                        Circle().strokeBorder(dotColor, lineWidth: 2).frame(width: 14, height: 14)
                    }
                }
                if !isLast { Rectangle().fill(Theme.Colors.line).frame(width: 2).frame(maxHeight: .infinity) }
            }
            .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(date.label).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                Text(date.value).font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                if let note = date.note {
                    Text(note).font(AppFont.jakarta(12, .semibold)).foregroundStyle(noteColor(date.state, note: note))
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
            Spacer(minLength: 0)
        }
    }

    private func noteColor(_ state: ExamKeyDateState, note: String) -> Color {
        if note == "Done" || note.contains("already applied") || note == "Today" { return Theme.Colors.green700 }
        if note == "Closed" { return Theme.Colors.ink500 }
        return Theme.Colors.blue700   // "N days left"
    }

    // MARK: - Fee

    private func feeCard(_ d: ExamApplicationDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fee").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            ForEach(d.feeLines) { line in
                HStack {
                    Text(line.label).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink700)
                    Spacer()
                    Text(line.amount).font(AppFont.jakarta(14, .heavy)).foregroundStyle(Theme.Colors.ink900)
                }
            }
            Rectangle().fill(Theme.Colors.divider).frame(height: 1)
            HStack {
                Text("Total").font(AppFont.jakarta(15, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text(d.feeTotal).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: d.paymentPaid ? "checkmark.circle.fill" : "indianrupeesign.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(d.paymentPaid ? "Payment: \(d.paymentNote)" : "Payment: \(d.paymentNote)")
                    .font(AppFont.jakarta(12, .semibold)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(d.paymentPaid ? Theme.Colors.green700 : Theme.Colors.amber800)
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(d.paymentPaid ? Theme.Colors.green50 : Theme.Colors.warningBackground, in: .rect(cornerRadius: 10))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }

    // MARK: - Papers

    private func papersCard(_ d: ExamApplicationDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(d.papersHeading).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                Spacer()
                Text("\(d.papers.count) papers").font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
            }
            ForEach(d.papers) { paper in
                HStack(spacing: 10) {
                    Text(paper.code).font(AppFont.jakarta(12, .heavy)).foregroundStyle(Theme.Colors.blue700)
                        .padding(.horizontal, 8).frame(height: 26).background(Theme.Colors.blue50, in: .rect(cornerRadius: 8))
                    Text(paper.name).font(AppFont.jakarta(14, .semibold)).foregroundStyle(Theme.Colors.ink900)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).dashboardCard(radius: 16)
    }
}

#Preview("Payment pending") {
    NavigationStack { ExamApplicationDetailView(examID: "e-ese", childID: nil) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}

#Preview("Approved") {
    NavigationStack { ExamApplicationDetailView(examID: "e-approved", childID: nil) }
        .environment(AppRouter()).environment(AppDependencies.previewZero)
}
