//
//  ContentView.swift
//  Track
//
//  Created by huang on 2023/1/28.
//

import SwiftUI
import AVKit

struct ContentView: View {
    var body: some View {
        NavigationView{
            MusicPlayer().navigationTitle("Music Player")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MusicPlayer : View {
    @State var data:Data = .init(count: 0)
    @State var title = ""
    @State var player:AVAudioPlayer!
    @State var playing = false
    @State var width:CGFloat = 0
    @State var songs = ["The Thrill Is Gone", "Made Right in the USA"]
    @State var finish = false
    @State var del = AVDelegate()

    @State var current = 0
    

    var body: some View {
        VStack(spacing:20){
            Image(uiImage: self.data.count == 0 ? UIImage(named: "music")! : UIImage(data: self.data)!)
                .resizable()
                .frame(width: 250, height: 250)
                .cornerRadius(15)
            Text(self.title).font(.title).padding(.top)
            ZStack(alignment: .leading){
                Capsule().fill(Color.black.opacity(0.08)).frame(height: 9)
                Capsule().fill(Color.red).frame(width: self.width, height: 9)
                    .gesture(DragGesture().onChanged({ (value) in
                        let x = value.location.x
                        self.width = x
                    }).onEnded({ (value) in
                        let x = value.location.x
                        let screen = UIScreen.main
                            .bounds.width - 30
                        let percent = x / screen
                        self.player.currentTime = percent * self.player.duration
                    }))
            }.padding(.top)
            HStack(spacing: UIScreen.main.bounds.size.width / 5 - 30){
                Button(action: {
                    if (self.current > 0) {
                        self.current -= 1
                        self.changSongs()
                    }
                }, label: {
                    Image(systemName: "backward.fill").font(.title)
                })
                Button(action: {
                    self.player.currentTime -= 15

                }, label: {
                    Image(systemName: "gobackward.15").font(.title)
                })
                Button(action: {
                    if (self.player.isPlaying){
                        self.player.pause()
                        self.playing = false
                    } else {
                        if (self.finish){
                            self.player.currentTime = 0
                            self.width = 0
                            self.finish = false
                        }
                        self.player.play()
                        self.playing = true
                    }
                }, label: {
                    Image(systemName: self.playing && !self.finish ? "pause.fill": "play.fill").font(.title)
                })
                Button(action: {
                    let increase = self.player.currentTime + 15
                    if (increase < self.player.duration) {
                        self.player.currentTime = increase
                    }
                }, label: {
                    Image(systemName: "goforward.15").font(.title)
                })
                Button(action: {
                    if (self.songs.count - 1 > self.current) {
                        self.current += 1
                        self.changSongs()
                    }
                }, label: {
                    Image(systemName: "forward.fill").font(.title)
                })
            }.padding(.top, 25)
                .foregroundColor(.black)
        }
        .padding()
        .onAppear{
            let url = Bundle.main.path(forResource: self.songs[self.current], ofType: "mp3")

            self.player = try! AVAudioPlayer(contentsOf: URL(filePath: url!))
            self.player.delegate = self.del
            self.player.prepareToPlay()
            self.getData()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
                if(self.player.isPlaying){
                    let screen = UIScreen.main.bounds.width - 30
                    let value = self.player.currentTime / self.player.duration
                    self.width = screen * CGFloat(value)
                }
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("Finish"), object: nil, queue: .main) { (_) in
                self.finish = true;
            }
        }
    }
    
    func getData() {
        let url = Bundle.main.path(forResource: "The Thrill Is Gone", ofType: "mp3")
        let asset = AVAsset(url: self.player.url!)
        for i in asset.commonMetadata{
            if (i.commonKey?.rawValue == "artwork") {
                let data = i.value as! Data
                self.data = data
            }
            if (i.commonKey?.rawValue == "title") {
                let title = i.value as! String
                self.title = title
            }
        }
    }
    
    func changSongs(){
        let url = Bundle.main.path(forResource: self.songs[self.current], ofType: "mp3")

        self.data = .init(count:0)
        self.title = ""
        self.player = try! AVAudioPlayer(contentsOf: URL(filePath: url!))
        self.player.delegate = self.del

        self.player.prepareToPlay()
        self.getData()
        self.playing = true
        self.finish = false;
        self.width = 0
        self.player.play()
    }
}

class AVDelegate:NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NotificationCenter.default.post(name:  Notification.Name("Finish"), object: nil)
    }
}
