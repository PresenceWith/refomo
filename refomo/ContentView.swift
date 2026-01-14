//
//  ContentView.swift
//  refomo
//
//  Created by Presence on 12/31/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1
    @State private var showSplash = true
    @State private var isDetailSheetPresented = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HistoryView(isDetailSheetPresented: $isDetailSheetPresented).tag(0)
                PomodoroView().tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scrollDisabled(isDetailSheetPresented)
            .ignoresSafeArea()
            .persistentSystemOverlays(.hidden)
            .statusBarHidden(true)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if reduceMotion {
                    showSplash = false
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { showSplash = false }
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        Color(.systemBackground)
            .ignoresSafeArea()
            .overlay(
                Circle()
                    .trim(from: 0.0417, to: 0.9583)
                    .stroke(Color.pomodoroAccent, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(90))
                    .frame(width: 100, height: 100)
            )
    }
}

#Preview { ContentView() }
