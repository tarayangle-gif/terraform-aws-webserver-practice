# 学習記録:2026年7月16日
## AWS × Terraform × GitHub 初挑戦の1日

---

## 今日のゴール
既に手動で構築していたAWS環境(VPC, サブネット, IGW, ルートテーブル, EC2, Webサイト表示)を、
**Terraformでコード化(IaC化)し、GitHubにポートフォリオとして公開する。**

---

## 全体の流れ(サマリー)

```
Terraformのインストール
    ↓ (互換性エラー発生)
AWS CLIのインストール
    ↓
aws configureで認証設定
    ↓
main.tf作成(VPC〜EC2まで一式をコード化)
    ↓
terraform init → plan → apply 成功
    ↓ (「Hello from Terraform!」表示成功)
Webサーバー自動構築(user_data)に挑戦
    ↓ (destroy → apply で再構築)
Git/GitHubでのバージョン管理に挑戦
    ↓ (複数のエラーを乗り越える)
GitHubへのpush成功、README追加
```

---

## 1. Terraformのインストール

### やったこと
- 公式サイト(https://developer.hashicorp.com/terraform/install )からWindows用ZIPをダウンロード
- 解凍して`terraform.exe`を`C:\terraform`に配置
- 環境変数PATHに`C:\terraform`を追加

### 🔴 つまずいたポイント
**「互換性がありません」というエラー**が発生。

**原因**: 32bit版と64bit版の取り違え(AMD64ではなく別のアーキテクチャ版をダウンロードしていた可能性)。

**解決**: 正しいバージョン(Windows/AMD64)を再ダウンロードして解決。

### 学び
- Windowsで新しいコマンドラインツールを入れる際は、PATHへの追加と、新しいコマンドプロンプトを開き直す必要があることを体感した。

---

## 2. AWS CLIのインストール & 認証設定

### やったこと
```bash
aws --version          # 未インストールだったため実施
aws configure           # Access Key ID, Secret Access Key, region(ap-northeast-1), output(json)を設定
aws sts get-caller-identity   # 認証確認 → 成功
```

### 学び
- IAMユーザーのアクセスキーを発行し、CLIやTerraformが「自分の代わりにAWSを操作できる」ようにする、という認証の仕組みを実際に設定して理解した。

---

## 3. main.tf作成 & Terraform実行

### 作成したリソース(コード化した内容)
- VPC
- サブネット(パブリック)
- インターネットゲートウェイ
- ルートテーブル(+ サブネットとの関連付け)
- セキュリティグループ(SSH:22, HTTP:80を許可)
- EC2インスタンス

### 実行コマンド
```bash
terraform init      # 成功
terraform plan       # 作成予定リソースの確認
terraform apply      # yesと入力して実行 → Apply complete!
```

### 🔴 つまずいたポイント
特に大きなエラーはなく、AMI IDとキーペア名を自分の環境に合わせて修正するだけでスムーズに進行。

### 学び
- 手動でポチポチ作っていた作業が、**1つのファイルと1コマンドで再現できる**という感覚を初めて体験。
- `plan`で「何が作られるか事前確認する」習慣の重要性を理解。

---

## 4. Webサーバー自動構築(user_data)

### やったこと
`aws_instance`に`user_data`を追加し、EC2起動時に以下を自動実行するよう設定。

```bash
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Hello from Terraform!</h1>" > /usr/share/nginx/html/index.html
```

`outputs.tf`を追加し、EC2のパブリックIPを自動表示するよう設定。

### 実行の流れ
```bash
terraform destroy    # 一度環境を削除(user_dataは新規作成時のみ実行されるため)
terraform apply       # 再作成
```

### 結果
ブラウザでパブリックIPにアクセス →  **「Hello from Terraform!」表示に成功!**

### 学び
- インフラ構築だけでなく、**サーバー起動後の初期設定まで自動化できる**ことを体験。
- Amazon Linux 2023では`yum`ではなく`dnf`を使うことを確認しながら進めた。

---

## 5. Git / GitHubでのバージョン管理(ここが一番のトラブル祭りだった)

### 5-1. Gitインストール & 初期設定

```bash
git --version
git config --global user.name "..."
git config --global user.email "..."
```

### 🔴 つまずいたポイント①:Author identity unknown
```
Author identity unknown
*** Please tell me who you are.
```
**原因**: user.name / user.emailを設定する前にcommitしようとした。
**解決**: 上記のconfigコマンドを実行後、再度commitして解決。

---

### 5-2. .gitignoreの作成

以下を`.gitignore`に設定(機密情報・巨大ファイル・不要ファイルを除外する目的)。

```
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.tfvars
```

### 🔴 つまずいたポイント②:ファイル名が正しく作成できない
メモ帳で`".gitignore"`と入力したつもりが、`=.gitignore=`という誤った名前で保存されてしまった。

**原因**: メモ帳の「ファイルの種類」設定や、ダブルクォーテーションの扱いの問題。

**解決**: コマンドプロンプトから直接作成する方法に切り替え。
```bash
notepad .gitignore
```
とコマンドで打つことで、正しいファイル名で新規作成・編集できることを発見。

---

### 5-3. GitHubへのpush(巨大ファイル問題)

```bash
git branch -M main
git remote add origin https://github.com/tarayangle-gif/terraform-aws-webserver-practice.git
git push -u origin main
```

### 🔴 つまずいたポイント③:100MB超のファイルでpush拒否
```
remote: error: File .terraform/providers/.../terraform-provider-aws_v6.55.0_x5.exe
is 846.65 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: GH001: Large files detected.
```

**原因**: `.gitignore`を作成する**前**に、すでに`.terraform`フォルダ(846MB)を`git add .`でコミットしてしまっていた。
`.gitignore`は「これから追跡しないファイル」を指定するもので、**過去のコミット履歴には遡って適用されない**ことが判明。

**最初に試した解決策(不十分だった)**:
```bash
git rm -r --cached .terraform
git rm --cached terraform.tfstate
git commit -m "Remove .terraform folder and add .gitignore"
git push
```
→ それでも同じエラーが再発。**過去のコミット履歴自体に巨大ファイルが残り続けていた**ため。

**最終的な解決策**: Gitの履歴自体をリセットしてやり直す。
```bash
rmdir /s /q .git      # .gitフォルダごと削除(履歴を完全リセット)
git init
git add .
git status             # ← ここで.terraformやtfstateが含まれていないことを確認
git commit -m "Initial commit: Terraform AWS web server setup"
git branch -M main
git remote add origin https://github.com/tarayangle-gif/terraform-aws-webserver-practice.git
git push -u origin main
```
→ **成功!**

### 学び
- `.gitignore`は「今後の追跡除外設定」であり、**過去のコミットには効かない**という重要な仕様を実体験で理解。
- 巨大ファイル・機密ファイルは、`.gitignore`を作る前に`git add`しないことが鉄則だと痛感。
- 学習用リポジトリだったからこそ「履歴ごとリセット」という力技で解決できたが、実務では慎重な対応(BFG Repo-Cleanerやgit filter-branch等)が必要になるケースもあると理解。

---

### 5-4. README追加時のpush拒否(fetch first)

```bash
git add README.md
git commit -m "Add README"
git push
```

### 🔴 つまずいたポイント④:リモートとローカルの履歴の食い違い
```
! [rejected]        main -> main (fetch first)
hint: Updates were rejected because the remote contains work that you do not have locally.
```

**原因**: `.git`フォルダを一度リセットしたことで、ローカルとリモート(GitHub上)の履歴が食い違っていた。

**解決**:
```bash
git pull origin main --allow-unrelated-histories
```

### 🔴 つまずいたポイント⑤:Vimに閉じ込められる
`git pull`実行後、マージコミットメッセージ入力のためVimエディタが自動起動し、操作方法がわからず一時停止。

```
Merge branch 'main' of https://github.com/...
# Please enter a commit message to explain why this merge is necessary,
~
```

**解決**:
```
Esc → :wq → Enter
```
で保存して脱出、無事コマンドプロンプトに復帰。

**再発防止の設定**:
```bash
git config --global core.editor "notepad"
```
今後はVimではなくメモ帳がデフォルトエディタになるよう設定。

---

## 6. 最終成果物

**GitHubリポジトリ**: `terraform-aws-webserver-practice`

含まれるファイル:
- `main.tf`(VPC〜EC2、user_dataまで一式のTerraformコード)
- `outputs.tf`(EC2のパブリックIP出力)
- `.gitignore`(機密情報・巨大ファイル除外設定)
- `README.md`(概要・使用技術・学んだことのまとめ)

---

## 今日1日で遭遇したエラー一覧(まとめ)

| # | エラー内容 | 原因 | 解決方法 |
|---|---|---|---|
| 1 | Terraformインストール時の互換性エラー | 誤ったアーキテクチャ版(32bit/64bit)をダウンロード | 正しい版(AMD64)を再ダウンロード |
| 2 | Author identity unknown | Gitのuser.name/emailが未設定 | git configで設定 |
| 3 | .gitignoreファイル名が正しく作成できない | メモ帳での保存形式の問題 | コマンドプロンプトから`notepad .gitignore`で作成 |
| 4 | 巨大ファイル(846MB)でpush拒否 | .gitignore作成前に.terraformフォルダをコミット済みだった | .gitフォルダごと削除し、履歴をリセットして再構築 |
| 5 | push rejected (fetch first) | ローカルとリモートの履歴の不一致 | git pull --allow-unrelated-histories |
| 6 | Vimエディタに閉じ込められる | マージコミットメッセージ入力画面の操作方法不明 | Esc → :wq → Enter で脱出、以後core.editorをnotepadに変更 |

---

## 今日の技術的到達点

- [x] AWSコンソールでのVPC/EC2手動構築(既習)
- [x] Terraformのインストール・環境構築
- [x] Terraformによるインフラのコード化(VPC, サブネット, IGW, ルートテーブル, セキュリティグループ, EC2)
- [x] user_dataによるWebサーバー自動構築(Nginx)
- [x] terraform init / plan / apply / destroy の一連操作
- [x] Gitの基本操作(init, add, commit, push, pull)
- [x] .gitignoreによる機密情報・不要ファイルの除外
- [x] GitHubでのポートフォリオ公開
- [x] マージコンフリクトや履歴不整合のトラブルシューティング

---

## 振り返り・所感

昨日まで「Terraformって何?」状態だったところから、1日で「AWS環境をコード化し、Gitでバージョン管理し、GitHubに公開する」というところまで到達した。

途中、何度もエラーに直面したが(互換性エラー、認証エラー、ファイル名の問題、巨大ファイルによるpush拒否、Vimへの閉じ込め)、その都度エラーメッセージを読み、原因を切り分けて、一つずつ解決していくことができた。

**このプロセス自体が、インフラエンジニアの実務で日常的に行われているトラブルシューティングそのものである。** 技術知識は今後も学び続ける必要があるが、「わからないことに直面してもパニックにならず、順序立てて解決する」という今日の経験は、今後の学習・実務においても大きな自信になる。

### 次回への課題・発展方向
- `variables.tf`によるパラメータの変数化
- RDS(データベース)を追加してWebサーバーと連携
- ALB(ロードバランサー)によるEC2複数台構成(冗長化)
- Terraformのstate管理(tfstateの仕組みをより深く理解する)
- 今回のような「巨大ファイルを誤ってコミットしてしまった場合」の、履歴を壊さずに修正する方法(BFG Repo-Cleaner等)の学習