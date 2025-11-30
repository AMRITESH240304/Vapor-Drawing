//
//  NotificationView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 11/11/25.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel

    var body: some View {
        VStack {
            if notificationViewModel.message.isEmpty {
                Text("No notifications yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(notificationViewModel.message, id: \.wssURL) { invite in
                            Text("\(invite.email) invited you to join a Drawing Session at \(invite.wssURL)")
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}


#Preview {
//    NotificationView(viewModel:NotificationViewModel())
}
