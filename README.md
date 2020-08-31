# ラズパイでカメラ

## カメラモジュール

### [Raspberry Pi High Quality Camera](https://static.raspberrypi.org/files/product-briefs/Raspberry_Pi_HQ_Camera_Product_Brief.pdf)

このモジュールはレンズ交換式で C/CS マウントレンズを装着して使用する。マウントでフランジバックの長さが異なる。Ｃマウント規格は17.526mm、ＣＳマウント規格は12.5mm。無限遠が出ればよい、ぐらいで適当にバックフォーカスを調整する。CS マウントには、カメラモジュール付属の C-CS アダプターは不要。

フォーカスはデスクトップ GUI でraspistill コマンドのライブプレビューで調整する。

## セットアップ

ラズパイとカメラモジュールはリボンケープルで接続する。
[Raspberry Pi 3 Model A+](https://www.raspberrypi.org/products/raspberry-pi-3-model-a-plus/) & [Raspberry Pi High Quality Camera](https://www.raspberrypi.org/products/raspberry-pi-high-quality-camera/) & 6mm CS-mount lens の例）

raspi-config から 5 Interfacing Options > P1 Camera でカメラを有効にする。

## コマンド

raspistill コマンドで撮影する。デスクトップ GUI で実行するとライブプレビューでフォーカス調整できる。

コマンドのオプション例）

```bash
$ raspistill --output image.jpg   # デフォルトの5秒後に撮影する。
$ raspistill --timeout 1000 --output image.jpg   # 1000 ms 後に撮影する。
$ raspistill --timestamp --timeout 1000 --output image-%d.jpg # 出力ファイル名は"%d" を unix timestamp で置き換えて出力する。
$ raspistill --timelapse 1000 --timeout 60000 --output image-%04d.jpg   # タイムラプス。1000 ms 毎に60000 ms 後まで撮影する。出力ファイル名は"%04d" をフレーム番号（連番でなくて、xxx）で置き換えて出力する。
$ raspistill --width 1920 --height 1080 --output image.jpg   # 1920 x 1080 [px] で撮影する。
```

コマンドオプションの --sharpness、--contrast、--brightness、--saturation は後処理のようだ。

## タイムラプス撮影

raspistill コマンドのタイムラプスではなく、systemd で一定時間毎にワンショットの raspistill コマンドを実行する。

ユニットファイル定義例）
ファイル名はunix timestamp、10 秒ごとに撮影する

```bash
$ cat raspi-timelapse.service
[Unit]
Description= Shooting timelapse images.

[Service]
Type=simple
ExecStart=/usr/bin/raspistill --timestamp --timeout 100 --output /mnt/nas/TimeLapse/%%d.jpg

[Install]
WantedBy=multi-user.target

$ cat raspi-timelapse.timer
[Unit]
Description= Shooting timelapse images.

[Timer]
AccuracySec=1
OnBootSec=10
OnUnitActiveSec=10
Unit=raspi-timelapse.service

[Install]
WantedBy=multi-user.target
```

タイムラプスを有効にする。

```bash
$ sudo cp raspi-timelapse.service /etc/systemd/system
$ sudo systemctl enable raspi-timelapse.service
Created symlink /etc/systemd/system/multi-user.target.wants/raspi-timelapse.service → /etc/systemd/system/raspi-timelapse.service.
$ sudo systemctl start raspi-timelapse.service
$ systemctl status raspi-timelapse.service
● raspi-timelapse.service - Shooting timelapse images.
   Loaded: loaded (/etc/systemd/system/raspi-timelapse.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Mon 2020-08-31 21:24:33 JST; 20s ago
  Process: 3439 ExecStart=/usr/bin/raspistill --timestamp --quality 90 --awb sun --timeout 1000 --output /mnt/nas/timelapse/%d.jpg (code=exited, status=0/SUCCESS)
 Main PID: 3439 (code=exited, status=0/SUCCESS)

 8月 31 21:24:31 raspberrypi3a systemd[1]: Started Shooting timelapse images..
 8月 31 21:24:33 raspberrypi3a systemd[1]: raspi-timelapse.service: Succeeded.

$ sudo cp raspi-timelapse.timer /etc/systemd/system
$ sudo systemctl enable raspi-timelapse.timer
Created symlink /etc/systemd/system/multi-user.target.wants/raspi-timelapse.timer → /etc/systemd/system/raspi-timelapse.timer.
$ sudo systemctl start raspi-timelapse.timer
$ systemctl status raspi-timelapse.timer
● raspi-timelapse.timer - Shooting timelapse images.
   Loaded: loaded (/etc/systemd/system/raspi-timelapse.timer; enabled; vendor preset: enabled)
   Active: active (waiting) since Mon 2020-08-31 21:25:42 JST; 20s ago
  Trigger: Mon 2020-08-31 21:25:52 JST; 10s ago

 8月 31 21:25:42 raspberrypi3a systemd[1]: Started Shooting timelapse images..
 $ systemctl --system list-timers
NEXT                         LEFT          LAST                         PASSED       UNIT                         ACTIVATES
Tue 2020-09-01 00:00:00 JST  2h 33min left Mon 2020-08-31 18:44:42 JST  2h 42min ago logrotate.timer              logrotate.service
Tue 2020-09-01 00:00:00 JST  2h 33min left Mon 2020-08-31 18:44:42 JST  2h 42min ago man-db.timer                 man-db.service
Tue 2020-09-01 06:24:47 JST  8h left       Mon 2020-08-31 18:44:42 JST  2h 42min ago apt-daily-upgrade.timer      apt-daily-upgrade.service
Tue 2020-09-01 17:25:47 JST  19h left      Mon 2020-08-31 18:44:42 JST  2h 42min ago apt-daily.timer              apt-daily.service
Tue 2020-09-01 19:23:19 JST  21h left      Mon 2020-08-31 19:23:19 JST  2h 3min ago  systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
n/a                          n/a           Mon 2020-08-31 21:26:53 JST  46ms ago     raspi-timelapse.timer        raspi-timelapse.service

6 timers listed.
Pass --all to see loaded but inactive timers, too.

```

タイムラプスを無効にする。

```bash
$ sudo systemctl stop raspi-timelapse.timer
$ sudo systemctl disable raspi-timelapse.timer
$ sudo rm /etc/systemd/system/raspi-timelapse.timer

$ sudo systemctl stop raspi-timelapse.service
$ sudo systemctl disable raspi-timelapse.service
$ sudo rm /etc/systemd/system/raspi-timelapse.service
```

画像シーケンスから動画を作成する。

```bash
$ ffmpeg -framerate 30 -pattern_type glob -i '*.jpg' -s 1920x1440 -vcodec libx264 -pix_fmt yuv420p -profile:v high -level 4.2 -preset medium -b:v 54M -r 30 output-filename.mp4   # コーデックはh.264、BDMVのビットレート。アスペクト比が 4:3 なので1920x1440にした。
```

## 参考

- [Raspberry Pi Camera Guide](https://magpi.raspberrypi.org/books/camera-guide)
- [picamera](https://picamera.readthedocs.io/en/release-1.13/)
