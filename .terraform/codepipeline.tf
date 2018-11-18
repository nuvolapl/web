resource "aws_iam_role" "codepipeline-web" {
    name               = "nuvola-codepipeline-web"
    assume_role_policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            }
        }
    ]
}
JSON
}

resource "aws_iam_role_policy" "codepipeline-web" {
    name   = "nuvola-codepipeline-web"
    role   = "${aws_iam_role.codepipeline-web.id}"

    policy = <<JSON
{
    "Statement": [
        {
            "Resource": "*",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": "ecs-tasks.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": "iam:CreateServiceLinkedRole",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": [
                        "ecs.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "cloudwatch:*",
                "s3:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ],
    "Version": "2012-10-17"
}
JSON
}

resource "aws_codepipeline" "web" {
    name     = "nuvola-pipeline-web"
    role_arn = "${aws_iam_role.codepipeline-web.arn}"

    artifact_store {
        location = "${var.s3-bucket-name}"
        type     = "S3"
    }

    stage {
        name = "Source"

        action {
            name             = "Source"
            category         = "Source"
            owner            = "ThirdParty"
            provider         = "GitHub"
            version          = "1"
            output_artifacts = ["source"]

            configuration {
                Owner  = "nuvolapl"
                Repo   = "web"
                Branch = "master"
            }
        }
    }

    stage {
        name = "Build"

        action {
            name             = "Build"
            category         = "Build"
            owner            = "AWS"
            provider         = "CodeBuild"
            version          = 1
            input_artifacts  = ["source"]
            output_artifacts = ["image-definition"]

            configuration {
                ProjectName = "${aws_codebuild_project.web.name}"
            }
        }
    }

    stage {
        name = "Production"

        action {
            name            = "Deploy"
            category        = "Deploy"
            owner           = "AWS"
            provider        = "ECS"
            input_artifacts = ["image-definition"]
            version         = 1

            configuration {
                ClusterName = "${var.ecs-cluster-name}"
                ServiceName = "${aws_ecs_service.web.name}"
                FileName    = "image-definition.json"
            }
        }
    }
}
