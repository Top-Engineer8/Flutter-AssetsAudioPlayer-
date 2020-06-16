import 'dart:io';

import 'package:dio/dio.dart';

import '../playable.dart';
import 'cache.dart';
import 'cache_downloader.dart';

AssetsAudioPlayerCacheManager _instance = AssetsAudioPlayerCacheManager._();

class AssetsAudioPlayerCacheManager {

  //singleton
  AssetsAudioPlayerCacheManager._();
  factory AssetsAudioPlayerCacheManager() => _instance;

  Dio _dio = Dio(); //expose it to make use capable to update it
  get dio => _dio;
  set dio(Dio newValue){
    if(newValue != null){
      _dio = newValue;
    }
  }

  Map<String, CacheDownloader> _downloadingElements = Map();

  Future<Audio> transform(AssetsAudioPlayerCache cache, Audio audio) async {
    if(audio.audioType != AudioType.network || audio.cached == false){
      return audio;
    }

    final String key = await cache.audioKeyTransformer(audio);
    final String path = await cache.cachePathProvider(audio, key);
    if(await _fileExists(path)){
      return audio.copyWith(
          path: path,
          audioType: AudioType.file
      );
    } else {
      try {
        await _download(audio, path);
        return audio.copyWith(
            path: path,
            audioType: AudioType.file
        );
      } catch (t){
        //TODO
      }
    }

    return audio; //do not change anything if error
  }

  Future<bool> _fileExists(String path) async {
    final File file = File(path);
    return await file.exists();
  }

  Future<void> _download(Audio audio, String intoPath) async {
    print(intoPath);
    if(_downloadingElements.containsKey(intoPath)) { //is already downloading it
      final downloader = _downloadingElements[intoPath];
      await downloader.wait();
    } else {
      final downloader = CacheDownloader(dio: _dio);
      _downloadingElements[intoPath] = downloader;
      downloader.downloadAndSave(
          url: audio.path,
          savePath: intoPath,
          headers: audio.networkHeaders ?? {},
          progressFunction: (received, total) {
            //TODO
          }
      );
      await downloader.wait();
      //download finished
      _downloadingElements.remove(intoPath);
    }
  }
}