# AWS Terraform Web Server Practice

## 概要
AWS上にVPCから手動構築した環境を、Terraformでコード化(IaC)した学習用リポジトリです。
EC2インスタンス起動時にNginxを自動インストール・起動する構成を実装しました。

## 構築した内容
- VPC(仮想ネットワーク)
- サブネット
- インターネットゲートウェイ
- ルートテーブル(ルーティング設定)
- セキュリティグループ(SSH, HTTPの許可)
- EC2インスタンス(user_dataによるNginx自動構築)

## 使用技術
- Terraform
- AWS(VPC, EC2)
- Amazon Linux 2023
- Nginx

## 実行方法
```bash
terraform init
terraform plan
terraform apply
```

## 学んだこと
- IaC(Infrastructure as Code)による環境構築の効率化・再現性
- ネットワーク設計(VPC, サブネット, ルーティング)の基礎理解
- user_dataを用いたインスタンス起動時の自動設定
- Gitによるバージョン管理、及び.gitignoreによる機密情報・不要ファイルの除外