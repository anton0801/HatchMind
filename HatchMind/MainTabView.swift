//
//  MainTabView.swift
//  Hatch Mind
//

import SwiftUI

enum MainTab: Int, CaseIterable {
    case dashboard, incubation, timeline, conditions, more

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .incubation: return "Eggs"
        case .timeline: return "Timeline"
        case .conditions: return "Conditions"
        case .more: return "More"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: return "house.fill"
        case .incubation: return "tray.full.fill"
        case .timeline: return "calendar.badge.clock"
        case .conditions: return "thermometer"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selected: MainTab = .dashboard
    @EnvironmentObject var prefs: UserPreferences
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .dashboard:
                    NavigationView { DashboardView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case .incubation:
                    NavigationView { IncubationListView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case .timeline:
                    NavigationView { TimelineView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case .conditions:
                    NavigationView { ConditionsView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                case .more:
                    NavigationView { MoreView() }
                        .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .padding(.bottom, 70)

            HMTabBar(selected: $selected)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct HMTabBar: View {
    @Binding var selected: MainTab
    @EnvironmentObject var prefs: UserPreferences

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selected = tab
                    }
                    prefs.haptic(.light)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(selected == tab ? .hmTextSecondary : .hmTextMuted.opacity(0.7))
                    .background(
                        ZStack {
                            if selected == tab {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LinearGradient(colors: [.hmYellow, .hmYellowGlow],
                                                         startPoint: .top, endPoint: .bottom))
                                    .matchedGeometryEffect(id: "selBg", in: nsTab)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            ZStack {
                Color.hmCard
                LinearGradient(colors: [.white.opacity(0.6), .clear],
                               startPoint: .top, endPoint: .bottom)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.hmDivider, lineWidth: 1)
        )
        .shadow(color: Color.hmYellow.opacity(0.18), radius: 16, y: 6)
    }

    @Namespace private var nsTab
}
