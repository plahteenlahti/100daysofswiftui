//
//  NyxoWidget.swift
//  NyxoWidget
//
//  Created by Perttu Lähteenlahti on 24.6.2020.
//  Copyright © 2020 Facebook. All rights reserved.
//

import WidgetKit
import SwiftUI



struct Commit {
    let message: String
    let author: String
    let date: String
}

struct LastCommitEntry: TimelineEntry {
    public let date: Date
    public let commit: Commit
}


@main
struct CommitCheckerWidget: Widget {
    private let kind: String = "NyxoWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CommitTimeline(), placeholder: PlaceholderView()) { entry in
            CommitCheckerWidgetView(entry: entry)
        }
        .configurationDisplayName("Nyxo Daily Stats")
        .description("Shows your daily information from Nyxo")
    }
}


struct CommitLoader {
    static func fetch(completion: @escaping (Result<Commit, Error>) -> Void) {
        let branchContentsURL = URL(string: "https://api.github.com/repos/apple/swift/branches/master")!
        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let commit = getCommitInfo(fromData: data!)
            completion(.success(commit))
        }
        task.resume()
    }

    static func getCommitInfo(fromData data: Foundation.Data) -> Commit {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let commitParentJson = json["commit"] as! [String: Any]
        let commitJson = commitParentJson["commit"] as! [String: Any]
        let authorJson = commitJson["author"] as! [String: Any]
        let message = commitJson["message"] as! String
        let author = authorJson["name"] as! String
        let date = authorJson["date"] as! String
        return Commit(message: message, author: author, date: date)
    }
}


struct CommitTimeline: TimelineProvider {
    
    public func snapshot(with context: Context, completion: @escaping (LastCommitEntry) -> ()) {
      let fakeCommit = Commit(message: "Fixed stuff", author: "John Appleseed", date: "2020-06-23")
      let entry = LastCommitEntry(date: Date(), commit: fakeCommit)
      completion(entry)
  }
    
    public func timeline(with context: Context, completion: @escaping (Timeline<LastCommitEntry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!

        CommitLoader.fetch { result in
            let commit: Commit
            if case .success(let fetchedCommit) = result {
                commit = fetchedCommit
            } else {
                commit = Commit(message: "Failed to load commits", author: "", date: "")
            }
            let entry = LastCommitEntry(date: currentDate, commit: commit)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct LastCommit: TimelineEntry {
    public let date: Date
    public let commit: Commit

    var relevance: TimelineEntryRelevance? {
        return TimelineEntryRelevance(score: 10) // 0 - not important | 100 - very important
    }
}

struct PlaceholderView : View {
    var body: some View {
        Text("Loading...")
    }
}

struct CommitCheckerWidgetView : View {
    let entry: LastCommitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("apple/swift's Latest Commit")
                .font(.system(.title3))
                .foregroundColor(.white)
            Text(entry.commit.message)
                .font(.system(.callout))
                .foregroundColor(.black)
                .bold()
   
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .top, endPoint: .bottom))
    }

    static func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm"
        return formatter.string(from: date)
    }
}

struct NyxoWidget_Previews: PreviewProvider {
  static var previews: some View {
    /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
  }
}
