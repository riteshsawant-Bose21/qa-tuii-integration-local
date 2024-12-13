#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import JenkinsJobCleanup
def JobCleanup = new JenkinsJobCleanup()
JobCleanup.CheckPendingJob("Fusion/Fusion-Server/Build-Fusion-Server", env.BRANCH_NAME)
def START_TS = ''
def VERSION = ''
def ARTIFACTORY_TARGET = "*"

pipeline {
	agent { label 'pro-win' }
	options {
		timeout(time: 2, unit: 'HOURS')
	}
	//Add build number and invoke cygwin's shell for Visual Studio
	environment {
		buildNumber="${env.BUILD_NUMBER}"
		buildDir="${env.WORKSPACE}"
		buildDirWin="${env.WORKSPACE}"
		buildDirWinPerl=env.buildDirWin.toString().replaceAll("\\\\","/")
		branchName="${env.CHANGE_BRANCH}"
		PATH="E:\\cygwin64\\bin;${env.PATH}"
		BuildType="Continuous"
		VersionFile="Application\\jenkins_build_version.properties"
		VersionHeader="./Application/version_number.h"
		BuildNumberFile="./Application/build_number.c"
// 		FWMajorVersion="""${sh(
// 						returnStdout: true,
// 						script: '''echo `cat ./Application/version_number.h | sed -e '/#[ \\t]*define[ \\t]\\+FW_MAJOR_VERSION/!d' | awk '{print $3}'`'''
// 					)}"""
// 		FWMinorVersion="""${sh(
// 						returnStdout: true,
// 						script: '''echo `cat ./Application/version_number.h | sed -e '/#[ \\t]*define[ \\t]\\+FW_MINOR_VERSION/!d' | awk '{print $3}'`'''
// 					)}"""
// 		FWBuilderNumber="""${sh(
// 						returnStdout: true,
// 						script: '''echo `cat ./Application/build_number.c | sed -e '/build_number.*\\"[ ]*[0-9]\\+\\"/!d' | sed -e 's/[^\\"]*\\"[ ]*\\([0-9]\\+\\).*/\\1/'`'''
// 					)}"""
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
					changeRequest target: 'master'
					branch 'master'
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
				// 			FWMajorVersion=FWMajorVersion.trim()
				// 			FWMinorVersion=FWMinorVersion.trim()
				// 			FWBuilderNumber=FWBuilderNumber.trim()
				// 			println("FWMajorVersion: ${FWMajorVersion}")
				// 			println("FWMinorVersion: ${FWMinorVersion}")
				// 			println("FWBuilderNumber: ${FWBuilderNumber}")
							START_TS=sh(returnStdout: true, script: 'date +%s').trim()
							START_DATE=sh(returnStdout: true, script: 'date').trim()
							env.branchName=env.CHANGE_BRANCH ?: env.BRANCH_NAME
							env.BuildType=params.BuildType
						}
					}

				}
				// stage('Setup') {
				// 	steps {
				// 		script {
				// 			sh '''
				// 				git submodule update --init --recursive
				// 				find -type f
				// 			'''
    //                         dir ('PSD_FW_NightlyBuild'){
    //                             checkout([
    //                               $class: 'GitSCM',
    //                               branches: [[name: '*/master']],
    //                               extensions: [[
    //                                 $class: 'CloneOption',
    //                                 shallow: true,
    //                                 depth:   1,
    //                                 timeout: 120
    //                               ]],
    //                               userRemoteConfigs: [[
    //                                 url:           'https://github.com/BoseProfessional/PSD_FW_NightlyBuild'
    //                               ]]
    //                             ])
    //                         }
				// 		}
				// 	}

				// }
				stage('Build') {
					steps {
						script {
							env.buildDir="${env.PWD}"
							env.gitHashShort=env.GIT_COMMIT.take(7).trim().toString()
							//sh 'chmod +x Jenkins/SetVersionProperty.sh'
							// ver=sh(returnStdout:true, script: './Jenkins/SetVersionProperty.sh').trim()
				// 			VERSION_PATCH="0"
				// 			ver="${FWMajorVersion}.${FWMinorVersion}.${VERSION_PATCH}-${buildNumber}+${env.gitHashShort}"
				// 			env.VERSION=ver
							println("buildDir: ${buildDir}")
							println("GIT_COMMIT: ${env.GIT_COMMIT}")
							println("VERSION: ${env.VERSION}")
							println("gitHashShort: ${env.gitHashShort}")									
				// 			println("ver: '${ver}'")
				// 			withCredentials([usernamePassword(credentialsId: 'pro-jenkins-artifactory', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
				// 				sh '''
				// 					mkdir -p buildtools/gcc-linaro-arm-linux-gnueabihf-4.7-2013.03
				// 					cd buildtools
				// 					curl -L -H 'X-JFrog-Art-Api:'$PASSWORD -O "https://boseprofessionaleast.jfrog.io/artifactory/pro-generic-local/BuildTools/Inferno_Buildtools.tar"
				// 					tar -xvf Inferno_Buildtools.tar
				// 					cp Inferno_BuildTools/gcc-linaro-arm-linux-gnueabihf-4.7-2013.03.tar.gz gcc-linaro-arm-linux-gnueabihf-4.7-2013.03/
				// 					tar -xvf gcc-linaro-arm-linux-gnueabihf-4.7-2013.03/gcc-linaro-arm-linux-gnueabihf-4.7-2013.03.tar.gz
				// 				'''
				// 			}
							sh '''
								echo "Environment: `uname`"
								make --version
								ls -l
								chmod +x build-fusion-server
								./build-fusion-server --package
								ls -l build/*
							'''
						}
					}
				}
				// stage('Deploy') {
				// 	environment {
				// 		ASSETS_CREDS = credentials('pro-jenkins-artifactory')
				// 	}
				// 	steps {
    // 					script {
    //                         EMBEDDED_PATH_PART=env.CHANGE_BRANCH ?: env.BRANCH_NAME
    //                         def server = Artifactory.server 'Bose-Artifactory'
    //                         //def fileName = "ControlSpace*.exe"
    //                         //def binaryPath = sh(returnStdout: true, script: "find . -name '${fileName}' | head -1").trim()
				// 			//def binaryFileName = sh(returnStdout: true, script: "basename -- '${binaryPath}'").trim()
				// 			sh '''find PSD_FW_NightlyBuild -type f'''
				// 			dir( 'PSD_FW_NightlyBuild/output_dir/' ) {
				// 				def targetPath = String.format(ARTIFACTORY_TARGET, env.BuildType, EMBEDDED_PATH_PART, env.VERSION)
				// 				def fileSpec = """{
				// 					"files": [
				// 						{
				// 						"pattern": "*.*",
				// 						"flat": "false",
				// 						"target": "${targetPath}"
				// 						}
				// 					]
				// 				}"""
				// 				println("fileSpec: ${fileSpec}")
				// 				server.upload spec:fileSpec
				// 			}
    // 					}
				// 	}
				// }
			}

			post {
				always {
					script {
						END_TS=sh(returnStdout: true, script: 'date +%s').trim()
						DIFF_TS=(END_TS as int) - (START_TS as int)
					}
				}

				success {
					script {
						if (SLACK_CHANNEL_ID) {
							slackSend(
								channel: "${SLACK_CHANNEL_ID}",
								timestamp: "${SLACK_TS}",
								color: 'good',
								message: "Build Finished Successfully - <${env.JOB_URL}|${env.JOB_NAME}> #${env.BUILD_NUMBER} (${DIFF_TS}s)"
							)
						}
					}
				}

				failure {
					script {
						if (SLACK_CHANNEL_ID) {
							slackSend(
								channel: "${SLACK_CHANNEL_ID}",
								timestamp: "${SLACK_TS}",
								color: 'danger',
								message: "Build Failed - <${env.JOB_URL}|${env.JOB_NAME}> #${env.BUILD_NUMBER} (${DIFF_TS}s)"
							)
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
