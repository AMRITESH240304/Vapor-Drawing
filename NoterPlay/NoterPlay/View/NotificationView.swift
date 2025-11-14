//
//  NotificationView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 11/11/25.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()

    var body: some View {
        VStack {
            if viewModel.message.isEmpty {
                Text("No notifications yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.message, id: \.wssURL) { invite in
                            Text(invite.message)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.getInviteFromWs()
        }
    }
}


#Preview {
//    NotificationView(viewModel:NotificationViewModel())
}
