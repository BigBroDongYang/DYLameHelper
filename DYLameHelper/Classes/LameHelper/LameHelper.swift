//
//  LameHelper.swift
//  DYLameHelper
//
//  Created by 3erfdsxf on 2022/3/14.
//

import Foundation
//import LAME_LAME_H

/// WAV转MP3
public func encodeToMp3(
    inWavPath: String,
    outMp3Path: String,
    onProgress: @escaping (Float) -> (Void),
    onComplete: @escaping () -> (Void)
) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: inWavPath) {
        print("WAV文件不存在")
        return
    }
    let encoderQueue = DispatchQueue(label: "com.audio.encoder.queue")
    encoderQueue.async {

        let lame = lame_init()
        lame_set_num_channels(lame, 2); // 双声道
        lame_set_in_samplerate(lame, 8000); // 8k采样率
        lame_set_brate(lame, 16);  // 压缩的比特率为16
        lame_set_quality(lame, 2);  // mp3音质
        lame_init_params(lame);

        let pcmFile: UnsafeMutablePointer<FILE> = fopen(inWavPath, "rb")
        fseek(pcmFile, 0 , SEEK_END)
        let fileSize = ftell(pcmFile)
        // Skip file header.
        let fileHeader = 4 * 1024
        fseek(pcmFile, fileHeader, SEEK_SET)

        let mp3File: UnsafeMutablePointer<FILE> = fopen(outMp3Path, "wb")

        let pcmSize = 1024 * 8
        let pcmbuffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(pcmSize * 2))

        let mp3Size: Int32 = 1024 * 8
        let mp3buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(mp3Size))

        var write: Int32 = 0
        var read = 0

        repeat {

            let size = MemoryLayout<Int16>.size * 2
            read = fread(pcmbuffer, size, pcmSize, pcmFile)
            // Progress
            if read != 0 {
                let progress = Float(ftell(pcmFile)) / Float(fileSize)
                DispatchQueue.main.sync { onProgress(progress) }
            }

            if read == 0 {
                write = lame_encode_flush(lame, mp3buffer, mp3Size)
            } else {
                write = lame_encode_buffer_interleaved(lame, pcmbuffer, Int32(read), mp3buffer, mp3Size)
            }

            fwrite(mp3buffer, Int(write), 1, mp3File)

        } while read != 0

        // Clean up
        lame_close(lame)
        fclose(mp3File)
        fclose(pcmFile)

        pcmbuffer.deallocate()
        mp3buffer.deallocate()

        DispatchQueue.main.sync { onComplete() }
    }
}


