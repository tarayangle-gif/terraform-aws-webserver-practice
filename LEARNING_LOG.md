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


---
---

# 学習記録:2026年7月29日(水)
## パブリック/プライベートサブネット & NAT Gateway構成への挑戦

## やったこと
- VPCをパブリックサブネットとプライベートサブネットの2階層に分離
- NAT Gatewayを構築し、プライベートサブネットから外部への一方通行の通信を実現
- 踏み台サーバー(bastion)を経由してのみプライベートサーバーにSSH接続できる構成を実装
- セキュリティグループで「publicからのSSHのみ許可」という設定を実装

## 構築した内容
- VPC(nat-practice-vpc)
- パブリックサブネット / プライベートサブネット
- インターネットゲートウェイ / NAT Gateway / Elastic IP
- パブリック用/プライベート用のルートテーブル
- パブリック用/プライベート用のセキュリティグループ
- 踏み台サーバー(public-bastion-server) / アプリサーバー(private-app-server)

## 🔴 つまずいたポイント

### ① terraform applyでyesが打てない
PowerShellで実行していたところ、確認画面(Do you want to perform these actions?)の後、入力ができない状態になった。
**解決**: コマンドプロンプト(cmd)に切り替えたところ解決。PowerShellとcmdで対話的な入力の挙動に差があることを確認。

### ② outputs.tfが古い構成のままでエラー
新しいmain.tf(public_server, private_server)に切り替えたが、outputs.tfが古いリソース名(aws_instance.web)を参照したままだったため、以下のエラーが発生。

**解決**: outputs.tfの中身を新しいリソース名(public_server, private_server)に合わせて書き換え。

### ③ main.tfが実は反映されていなかった
outputs.tfを直しても「Reference to undeclared resource」というエラーが発生。
原因は、実際のmain.tfがまだ古い構成(aws_instance.web)のままで、新しい構成の内容が保存されていなかったこと。
**解決**: main.tfの中身を新しい構成の内容に書き換えて保存し直し、terraform planで再確認してから apply。

## 動作確認でできたこと
- 踏み台サーバーへのSSH接続
- プライベートサーバーへの直接SSH接続が「できない」ことを確認(セキュリティの効果を実感)
- 踏み台経由(`ssh -A`によるエージェント転送)でのプライベートサーバーへの接続に成功
- プライベートサーバー内から`ping google.com`を実行し、NAT Gateway経由で外部通信ができることを確認

## 学び
- パブリック/プライベートサブネットの分離という、実務で標準的なセキュリティ設計を実際に構築できた
- NAT Gatewayの「外からは入れないが、自分からは出られる」という一方通行の仕組みを、`ping`コマンドで体感的に理解できた
- Terraformでコードを変更した際は、**ファイルの保存漏れ・反映漏れがないか常に確認する**という実務的な注意点を学んだ
- 学習用のNAT Gatewayは課金対象になるため、確認後は速やかに`terraform destroy`する習慣が身についた


---

# 学習記録:2026年7月29日(水)
## GitHub Actions × Terraform:CI/CDと「状態管理」の壁にぶつかった一日

## やったこと
- GitHub Actionsを使い、pushをきっかけにTerraformを自動実行する仕組み(CI/CD)に挑戦
- IAMユーザー・アクセスキー・GitHub Secretsを使った認証設定
- Terraform/AWS Providerのバージョン不整合の解決
- S3をバックエンドとした tfstate の共有管理を実装

## 🔴 つまずいたポイント(今回は特に多かった)

### ① AuthFailure:認証情報が無効
GitHub Actions上でterraform applyを実行したところ、以下のエラーが発生。

**原因**: GitHub Secretsに登録したアクセスキーの情報に問題があった。
**やってしまったこと**: 原因切り分けの過程で、誤ってIAMユーザー自体を削除してしまった。
**解決**: 新しいIAMユーザーを作成し、アクセスキーを再発行。AdministratorAccessを付与し、aws configureとGitHub Secretsの両方を新しい値で更新。

### ② No valid credential sources found
Secretsを更新しても認証が通らず、調査したところGitHub Secretsの登録名が
`AWS_ACCESS_KEY`(本来は`AWS_ACCESS_KEY_ID`)になっており、
ワークフローファイルが参照している名前と一致していなかった。
**解決**: Secretsの名前を正確に`AWS_ACCESS_KEY_ID`に登録し直して解決。

### ③ InvalidHttpRequest: Unable to parse request
認証は通ったが、Security GroupやSubnet作成時にこのエラーが頻発。
**原因の仮説**: ローカル(Windows, Terraform v1.15.8, AWS Provider v6.55.0)と
GitHub Actions(Ubuntu環境)でのバージョン不一致、
またはAWS Provider v6系の新しい仕様(リソース単位のregion指定など)が影響している可能性。
**結果**: 今回は根本原因の完全特定には至らず、ローカルでの検証に切り替えて対応。
→ 今後の課題として持ち越し。

### ④ VpcLimitExceeded / AddressLimitExceeded
何度も試行錯誤する中で、削除し忘れたVPCやElastic IPが溜まり、
AWSアカウントのリソース上限に達してエラーが発生。
**解決**: AWSコンソールから、EC2→NAT Gateway→Elastic IP→VPCの順で手動削除。
Elastic IPは関連付け解除直後は解放できないことがあり、少し時間を置く必要があった。

### ⑤ 【今日一番の学び】destroyしても何も消えない問題
GitHub Actions上でapply→destroyを試したところ、
applyでは確かにAWS上にリソースが作られるのに、
destroyを実行すると「Resources: 0 destroyed」となり、実際には何も消えなかった。

**原因**: GitHub Actionsは、実行のたびに使い捨ての仮想環境を新しく用意する仕組みのため、
tfstate(何を作ったかの記録)をローカルのファイルとして管理していると、
実行が終わるたびにtfstateごと消滅してしまう。
そのため、「apply時の記録」と「destroy時に参照する記録」が別物になり、
destroyしても何も認識できない状態になっていた。

**解決**: S3バケットを作成し、main.tfに`backend "s3"`を設定。
tfstateを「どの実行環境からでも参照できる共有の場所」に置くことで解決。
ローカルから`terraform apply`→`terraform destroy`を実行したところ、
「Destroy complete! Resources: 14 destroyed.」と、正しく全リソースが削除されることを確認できた。

## 今日の一番の理解


## 学び
- CI/CDパイプラインを組む際、認証情報(Secrets)の名前は1文字のズレも許されないため、正確な突き合わせ確認が重要
- Terraform/Providerのバージョンは、ローカルとCI環境で必ず揃えるべき
- AWSリソースには上限があり、検証中の消し忘れが積み重なると新規作成もできなくなる
- **tfstateの管理場所(ローカル/リモート)という概念は、チーム開発やCI/CDの基本前提であり、今回身をもって理解できた**
- 原因が特定しきれない問題(InvalidHttpRequestエラー)に直面した際、深追いせず「確実に検証できる方法(ローカル実行)」に切り替える判断も、実務で必要な選択肢の一つだと学んだ

## 今後の課題
- GitHub Actions上でのInvalidHttpRequestエラーの根本原因の特定
- GitHub Actions用に、tfstateをロックする仕組み(DynamoDBなど)も学ぶと、より実務に近い構成になる
- CI用ワークフローの自動apply(push時実行)は事故のもとになるため、pull_requestや手動実行(workflow_dispatch)を基本とする設計に変更済み

本日の追加分

# Terraform × GitHub Actions による AWS 完全自動構築（CI/CD）パイプライン

GitHub へのコード送信（`git push`）をトリガーとし、クラウド上の Runner（ロボット）が自動でテストから AWS 上への本番リソース構築までを行う **継続的デプロイ（CD: Continuous Deployment）パイプライン** です。

手元のローカル端末に依存せず、クラウド環境で一貫したプロビジョニングを実行できる高度なインフラ開発環境を構築しました。

---

## 🎯 プロジェクトの目的と概要

* **従来の課題**: 手元の端末から手動で `terraform apply` を実行する場合、実行環境の差異、ローカル鍵の取り扱いミス、手動操作によるオペレーションミスなどのリスクが存在する。
* **解決策**: GitHub Actions による CI/CD パイプラインを導入。コード差分が発生した時点で自動でシミュレーション（Plan）を行い、問題がなければ自動で本番環境へ反映（Apply）させる「完全自動化」を実現。

---

## 🏗️ 構築した AWS インフラ構造 (Total: 14 リソース)

Terraform コード（`main.tf`）により、以下の AWS ネットワークおよびコンピュート環境が全自動でプロビジョニングされます。

* **Network**: 
  * VPC（仮想ネットワーク空間の切り出し）
  * Public Subnet（Web サーバー配置用サブネット）
  * Internet Gateway（外部インターネット通信の有効化）
  * Route Table / Route Table Association（ルーティング情報の管理と紐付け）
* **Compute / Security**:
  * EC2 Instance（Linux Web サーバー）
  * Elastic IP (EIP)（サーバーへの固定パブリックIP付与）
  * Security Group（HTTP 80 / SSH 22 ポートの通信制御）

---

## 🔄 CI/CD パイプラインのアーキテクチャ & ワークフロー

```text
[ ローカル PC ]
    │  1. git push (main / master ブランチ)
    ▼
[ GitHub Repository ]
    │  2. GitHub Actions ワークフローが自動検知・起動
    ▼
[ Runner: ubuntu-latest (使い捨て仮想マシン) ]
    │
    ├─ 3. Checkout
    │      リポジトリの最新ソースコードを取得
    │
    ├─ 4. Setup Terraform
    │      Terraform CLI 環境をセットアップ
    │
    ├─ 5. Terraform Init
    │      AWS プロバイダープラグインの初期化
    │
    ├─ 6. Terraform Plan  【CI 段階】
    │      既存の構文チェックおよび変更差分のシミュレーション
    │
    └─ 7. Terraform Apply (-auto-approve)  【CD 段階】
           AWS へのリクエストを自動発行し、全リソースを作成
```

---

## 🛠️ 導入した技術スタック (Tech Stack)

| カテゴリ | 技術・サービス | 用途・詳細 |
| :--- | :--- | :--- |
| **IaC** | Terraform (v1.x) | AWS リソースのコードによる宣言的定義 |
| **CI/CD** | GitHub Actions | 自動テスト・自動デプロイワークフローの実行環境 |
| **Cloud** | AWS (Amazon Web Services) | VPC, EC2, SG, EIP などの本番インフラ |
| **Region** | Asia Pacific (Tokyo: `ap-northeast-1`) | 低遅延・日本国内向けのリージョン指定 |
| **Secret Auth** | GitHub Actions Secrets | AWS アクセスキー情報の安全な秘匿化 |

---

## 💡 トラブルシューティング & 実装上の学び (Learnings)

本パイプラインの構築過程において、実務で頻出するいくつかの技術的課題を特定し、解決しました。

### 1. 認証情報のスコープ漏れによる `AuthFailure (401)` の解決
* **問題**: `terraform plan` までは正常終了するが、`terraform apply` ステップで `No valid credential sources found` および `StatusCode 401` エラーが発生。
* **原因**: GitHub Actions の各ステップ（`step`）は完全に独立した環境で動くため、`apply` ステップに対して `env:`（環境変数）が伝播していなかった。
* **解決**: `Terraform Apply` ステップにも明確に `AWS_ACCESS_KEY_ID` と `AWS_SECRET_ACCESS_KEY` を割り当てることで認証をパスさせました。

### 2. YAML 構文エラー（インデント不整合）の解消
* **問題**: ワークフロー実行時に `Invalid workflow file (yaml syntax error)` が発生。
* **原因**: `- name: Terraform Apply` の先頭スペース数が他のステップとズレており、YAML インデント階層構造が破損していた。
* **解決**: インデント（半角スペース2文字単位）を全ステップで厳密に統一し、文法エラーを解消。

### 3. CI/CD 環境における非対話型実行 (`-auto-approve`)
* **問題**: 通常の `terraform apply` はターミナルで `yes` の対話入力が必要なため、CI/CD ロボットが停止してしまう。
* **解決**: `-auto-approve` オプションを付与し、確認ステップを自動スキップさせることで全自動デプロイを実現。

---

## 📄 最終的なワークフロー定義コード (`.github/workflows/terraform.yml`)

```yaml
name: 'Terraform CI/CD Pipeline'

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]

permissions:
  contents: read

jobs:
  terraform:
    name: 'Terraform Automate'
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    - name: Terraform Init
      run: terraform init
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: 'ap-northeast-1'

    - name: Terraform Plan
      run: terraform plan
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: 'ap-northeast-1'

    - name: Terraform Apply
      run: terraform apply -auto-approve
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: 'ap-northeast-1'
```

---

## 🚀 今後の拡張・改善予定 (Next Steps)

* [ ] **tfstate（状態管理）のリモート化**
  S3 バケットおよび DynamoDB（排他ロック用）へ `terraform.tfstate` を保存し、チーム開発およびステート保持に対応させる。
* [ ] **Manual Approval（手動承認ゲート）の導入**
  本番（Production）デプロイ前に、GitHub 上でエンジニアの明示的な「承認ボタン」を必要とするセキュリティ設計への強化。
* [ ] **自動削除（Destroy）ワークフローの追加**
  検証用環境の削除コストを削減するため、手動実行可能な `terraform destroy` ワークフローの構築。