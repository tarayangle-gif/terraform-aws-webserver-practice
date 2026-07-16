# AWS Terraform Web Server Practice

## 概要
AWS上にVPCから構築し、Terraformでコード化(IaC)した学習用リポジトリです。
EC2起動時にNginxを自動インストールする構成を実装しました。

## 構築した内容
- VPC / サブネット / インターネットゲートウェイ / ルートテーブル
- セキュリティグループ(SSH, HTTP許可)
- EC2インスタンス(user_dataによるNginx自動構築)

## 使用技術
- Terraform
- AWS(EC2, VPC)
- Amazon Linux 2023 / Nginx

## 学んだこと
- IaCによるインフラの再現性・効率化
- ネットワーク設計(VPC, サブネット, ルーティング)の基礎
- Gitによるバージョン管理と機密情報の適切な除外(.gitignore)
