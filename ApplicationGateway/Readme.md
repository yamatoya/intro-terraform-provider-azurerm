# 仮想マシン

WindowsとLinuxそれぞれの仮想マシンを構築するためのテンプレートです。

* Windows
 * Windows Server 2019 のサーバーイメージを使用しています。
 * RDPポートを開けています。
* Linux
 * Ubuntuをインストールしています。
 * 22番ポートを開けています。

# ポイント

* `storage_image_reference` でイメージを選択するときには、 `version` 指定に注意が必要です。複数ヒットした場合は構築に失敗してしまいます。 `latest` などを指定しましょう。
* Windowsのイメージ指定は若干はまるかもしれません。フォーマット的なところで。

```
  storage_image_reference {
    # https://docs.microsoft.com/ja-jp/azure/virtual-machines/windows/cli-ps-findimage
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
```
