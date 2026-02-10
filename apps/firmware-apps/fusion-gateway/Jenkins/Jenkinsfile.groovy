#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import JenkinsJobCleanup
def JobCleanup = new JenkinsJobCleanup()
def VERSION = ''
def NEXUS_TARGET = "Fusion-Gatway/%s/%s"

pipeline {
	agent { label 'pro-win' }
	options {
		timeout(time: 2, unit: 'HOURS')
	}
	environment {
		NEXUS_URL = '10.100.109.38:8081'
		CREDENTIALS_ID = 'jenkins-artifact-deployer'
		buildNumber="${env.BUILD_NUMBER}"
		buildDir="${env.WORKSPACE}"
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
            						  chmod +x ./build-fusion-gateway
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
								./build-fusion-gateway --package
								ls -l build/*
							'''
						}
					}
				}
				stage('Deploy') {
					steps {
	    					script {
	                   				dir( 'build/' ) {
	                                			EMBEDDED_PATH_PART=env.CHANGE_BRANCH ?: env.BRANCH_NAME
	    						    	def artifacts = []
								def filesToUpload = findFiles(glob: 'fusion-gateway_*.tar.gz')
								filesToUpload.each { file ->
	                                    				artifacts.add([artifactId: file.name.substring(0, file.name.lastIndexOf('_')), file: file.path, type: 'tar.gz'])
								}
	    						    	def targetPath = String.format(NEXUS_TARGET, env.BuildType, EMBEDDED_PATH_PART)
								nexusArtifactUploader(
				                                    nexusVersion: 'nexus3',
				                                    protocol: 'http',
				                                    nexusUrl: "${NEXUS_URL}",
				                                    repository: "pro-fusion-local/${targetPath}",
				                                    version: "${env.VERSION}",
				                                    groupId: "",
				                                    credentialsId: "${CREDENTIALS_ID}",
				                                    artifacts: artifacts
				                                )
	    					    	}
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
				githubNotify( "Build-fusion-gateway", "Build succeeded", "SUCCESS" );
			  }
			}
        }
		failure {
			script {
			  if( env.CHANGE_ID ) {
				githubNotify( "Build-fusion-gateway", "Build failed", "FAILED" );
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
