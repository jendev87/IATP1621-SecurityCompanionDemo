//
//  ContentView.swift
//  SecurityCompanionDemo
//
//  Created by thinkpalm on 10/11/26.
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer
    @Bindable var session: AuthSessionManager

    init(container: AppContainer) {
        self.container = container
        self.session = container.sessionManager
    }

    var body: some View {
        if session.isAuthenticated {
            ZoneListView(
                viewModel: container.makeZoneListViewModel(),
                container: container
            )
        } else {
            LoginView(session: session)
        }
    }
}

#Preview {
    ContentView(container: AppContainer())
}
