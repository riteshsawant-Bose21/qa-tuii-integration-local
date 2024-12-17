#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import JenkinsJobCleanup
def JobCleanup = new JenkinsJobCleanup()
def VERSION = ''
def ARTIFACTORY_TARGET = "pro-fusion-local/Fusion-Server/%s/%s/%s/%s"

pipeline {
	agent { label 'pro-win' }
	options {
		timeout(time: 2, unit: 'HOURS')
	}
	environment {
		buildNumber="${env.BUILD_NUMBER}"
		buildDir="${env.WORKSPACE}"
		branchName="${env.CHANGE_BRANCH}"
		BuildType="Continuous"
		VersionFile="fusion/VERSION"
	}
	stages {
    stage('Setup parameters') {
            steps {
                script { 
                    properties([
                        parameters([
                            choice(
                                choices: ['Continuous', 'Nighty', 'Release'], 
                                name: 'BuildType'
                            )
                        ])
                    ])
                }
            }
        }
		stage('Check') {
			when {
				anyOf {
					changeRequest target: 'main'
					branch 'main'
					changeRequest target: 'develop'
					branch 'develop'
					changeRequest target: 'feat/jenkins-pipeline'
					branch 'feat/jenkins-pipeline'
					changeRequest target: 'release/.*', comparator: 'REGEXP'
					branch pattern: 'release/.*', comparator: 'REGEXP'
				}
			}
			stages {
				stage('Prepare') {
					steps {
						script {
							env.branchName=env.CHANGE_BRANCH ?: env.BRANCH_NAME
							env.BuildType=params.BuildType
							sh """
            						  chmod +x ./Jenkins/SetVersionProperty.sh
            						  chmod +x ./build-fusion-server
          						"""
						}
					}

				}
				stage('Build') {
					steps {
						script {
							env.buildDir="${env.PWD}"
							env.gitHashShort=env.GIT_COMMIT.take(7).trim().toString()
							ver=sh(returnStdout:true, script: './Jenkins/SetVersionProperty.sh').trim()
							env.VERSION=ver
							println("buildDir: ${buildDir}")
							println("GIT_COMMIT: ${env.GIT_COMMIT}")
							println("VERSION: ${env.VERSION}")
							println("gitHashShort: ${env.gitHashShort}")									
							println("ver: '${ver}'")
							sh '''
								echo "Environment: $(uname -a)"
								make --version | head -1
								export PATH="/e/Program Files/Go/Bin":$PATH >/dev/null 2>&1
								./build-fusion-server --package
								ls -l build/*
							'''
						}
					}
				}
				stage('Deploy') {
					environment {
						ASSETS_CREDS = credentials('pro-jenkins-artifactory')
					}
					steps {
    					script {
                            				EMBEDDED_PATH_PART=env.CHANGE_BRANCH ?: env.BRANCH_NAME
                            				def server = Artifactory.server 'Bose-Artifactory'
                            				def fileName = "fusion-server_*.tgz"
                            				def binaryPath = sh(returnStdout: true, script: "find . -name '${fileName}' | head -1").trim()
							def binaryFileName = sh(returnStdout: true, script: "basename -- '${binaryPath}'").trim()
							def targetPath = String.format(ARTIFACTORY_TARGET, env.BuildType, EMBEDDED_PATH_PART, env.VERSION, binaryFileName)
							def fileSpec = """{
								"files": [
									{
									"pattern": "${binaryPath}",
									"flat": "false",
									"target": "${targetPath}"
									}
								]
							}"""
							println("fileSpec: ${fileSpec}")
							server.upload spec:fileSpec
    						}
					}
				}
			}
		}
	}

	post {
		success {
			script {
			  if( env.CHANGE_ID ) {
				githubNotify( "Build-Fusion-Server", "Build succeeded", "SUCCESS" );
			  }
			}
        }
		failure {
			script {
			  if( env.CHANGE_ID ) {
				githubNotify( "Build-Fusion-Server", "Build failed", "FAILED" );
			  }
			}
        }
 	cleanup {
 			retry(3){
 			    cleanWs()
 			}
 		}
	}
}
