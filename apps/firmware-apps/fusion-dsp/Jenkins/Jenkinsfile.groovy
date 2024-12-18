#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import java.util.regex.Pattern
import JenkinsJobCleanup
import groovy.json.JsonOutput
def JobCleanup = new JenkinsJobCleanup()
// JobCleanup.CheckPendingJob("Avenger/Frontend/pro-peak-betacon-mac", env.BRANCH_NAME)

ARTIFACTORY_TARGET = "avenger-frontend-repo/pro-peak-betacon/electron/%s/%s"

pipeline {
	agent { label 'pro-fusion-container' }
	
	options {
		timeout(time: 2, unit: 'HOURS')
		skipDefaultCheckout()
	}
	environment {
	        buildDir="${env.WORKSPACE}"
    }
	
	stages {
// 		stage('clone') {
// 			steps {
// 				script {
// 					def branch = env.CHANGE_BRANCH ?: env.BRANCH_NAME
// 					retry(3){
// 						checkout([$class: 'GitSCM',branches: [[name: "${branch}"]],
// 							  doGenerateSubmoduleConfigurations: false,
// 							  extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true, timeout: 30]],
// 							  userRemoteConfigs: [[credentialsId: '5801fa82-23a0-4402-868e-7ca5fa2c6638',
// 									       name: 'pro-peak-betacon',
// 									       url: 'https://github.com/BoseProfessional/pro-peak-betacon.git']]
// 							 ])
// 					}
// 					// Set github info in env. variable
// 					githubInfo()
// 				}
// 			}
// 		}
		stage('Check') {
			when {
				anyOf {
					changeRequest target: 'master'
					branch 'master'
					changeRequest target: 'devops-migration'
					branch 'devops-migration'
				}
			}
			stages {
				stage('Prepare') {
				    environment {
                        GIT_KEY = credentials("bosepro-auto-ssh")
                    }
					steps {
				// 		script {
				// 		  if( env.CHANGE_ID ) {
				// 			githubNotify( "pro-peak-betacon-mac", "Stage: Prepare ...", "PENDING" )
				//   		  }
				// 		}
				// 		sh'''
				// 		    mkdir /home/builder/.ssh
				// 		    cp ${GIT_KEY} /home/builder/.ssh/id_rsa
				// 		'''
				// 		addGithubToKnownHosts()
						sh'''
						    export PATH=/yocto/sources/poky/bitbake/bin:$PATH
						    cd /yocto/build
						    bitbake fusion-image
						'''
						
					}
				}

				// stage('Install') {
				// 	steps {
				// 		script {
				// 		  if( env.CHANGE_ID ) {
				// 			githubNotify( "pro-peak-betacon-mac", "Stage: Install ...", "PENDING" )
				//   		  }
				// 		}
				// 		//Adding environment variables and setting environment for npm
				// 		sh '''
				// 		export NVM_DIR=~/.nvm
    //                                             source ~/.nvm/nvm.sh
				// 		nvm install 14.17.4
				// 		nvm use 14.17.4
				// 		'''
				// 		sh '''
				// 		trials=2
				// 		n=0
				// 		until [ "$n" -ge "$trials" ]
				// 		do
				// 			yarn install --force --ignore-optional --verbose && break
				// 			n=$((n+1))
				// 			sleep 1
				// 		done'''
				// 	}
				// }
				
				// stage('Build Electron Mac') {
				// 	steps {
				// 		script {
				// 				if( env.CHANGE_ID ) {
				// 					githubNotify( "pro-peak-betacon-mac", "Stage: Build Electron Mac ...", "PENDING" )
				//   		  		}
				// 				ELECTRON_RELEASE_V=sh(returnStdout: true, script: "node ./scripts/getElectronVersion.js").trim()
				// 				env.ProductFileName="Bose Professional Configuration Utility"
				// 				withCredentials([usernamePassword(credentialsId: 'mac-signing-unlock-creds', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
				// 				sh '''security unlock-keychain -p $PASSWORD'''
				// 				sh "cd container && yarn install --verbose"
				// 				sh """
				// 				  cd container
				// 				  yarn release:mac
				// 				  codesign --force  --verbose --deep --options runtime --sign \"Developer ID Application: Transom Post Opco LLC (7FDK3RUF89)\" -vvv \"dist/${ProductfileName}-${ELECTRON_RELEASE_V}.dmg\"
				// 				  codesign -vvv -d --deep --verbose  \"dist/${ProductFileName}-${ELECTRON_RELEASE_V}.dmg\"
				// 				  mv \"dist/${ProductFileName}-${ELECTRON_RELEASE_V}.dmg\" \"dist/${ProductFileName}.dmg\"
				// 			          ls \"dist/\"
				// 				"""
				// 			}

				// 		}
				// 	}
				// }
				
				// stage('Notarize mac build') {
				// 	steps {
				// 		script {
				// 			if( env.CHANGE_ID ) {
				// 				githubNotify( "pro-peak-betacon-mac", "Stage: Notarize mac build ...", "PENDING" )
				// 			}
				// 			ELECTRON_RELEASE_V=sh(returnStdout: true, script: "node ./scripts/getElectronVersion.js").trim()
				// 			withCredentials([usernamePassword(credentialsId: 'ControlSpaceRemoteNotarization',
    //                             				passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
				//                                 sh '''
				//                                     cd container
				// 				    ls
				// 				    # Setup and Notarization and staple the ticket to the pkg file
				//                                     #
				//                                     echo ""
				//                                     echo "Setup and Notarization and staple the ticket to the pkg file"
				//                                     echo ""
				                                    
				//                                     export DEVELOPER_DIR=/Applications/Xcode15.app #Need xcode 10 or greater.
				//                                     xcode-select -p
				                                    
				//                                     echo "Starting Notarization $(date)"
				//                                     xcrun --verbose notarytool submit "$buildDir/container/dist/${ProductFileName}.dmg" --apple-id $USERNAME --password $PASSWORD --team-id "7FDK3RUF89" --wait
				//                                     echo "Finished Notarization $(date)"
													
				//                                     echo "Starting Tag Stapling $(date)"
				//                                     xcrun --verbose stapler staple "$buildDir/container/dist/${ProductFileName}.dmg"
				//                                     echo "Finished Tag Stapling $(date)"
				//                                 '''
				// 				requestUUID = parseLog(currentBuild, Pattern.compile('id: '), 100, true, 1)
				// 				if (requestUUID)
				// 				  requestUUID = requestUUID.substring(requestUUID.indexOf(':') + 2)
				// 				println "Captured UUID is:$requestUUID."
				// 			sh """
				// 				ls -al $buildDir/container/dist/
				// 				cd container
				// 				mv \"dist/${ProductFileName}.dmg\" \"dist/${ProductFileName}-${ELECTRON_RELEASE_V}.dmg\"
				//                                 cp \"dist/${ProductFileName}-${ELECTRON_RELEASE_V}.dmg\" \".\"
				// 				ls -al $buildDir/container/dist/
				// 			"""
				// 			}
				// 		}
				// 	}
				// }

				// stage('Artifactory') {
				// 	steps {
				// 		script {
				// 			if( env.CHANGE_ID ) {
				// 				githubNotify( "pro-peak-betacon-mac", "Stage: Artifactory ...", "PENDING" )
				// 			}
				// 			EMBEDDED_PATH_PART=env.CHANGE_BRANCH ?: env.BRANCH_NAME
				// 			ELECTRON_RELEASE_V=sh(returnStdout: true, script: "node ./scripts/getElectronVersion.js").trim()
				// 			if (BRANCH_NAME == 'master') {
				// 				PATH_PART=""
				// 			} else {
				// 				PATH_PART="${EMBEDDED_PATH_PART}/"
				// 			}
			
				// 			env.gitHashShort=env.GIT_COMMIT.take(7).trim().toString()
				// 			env.VERSION="${ELECTRON_RELEASE_V}" + "." + env.BUILD_NUMBER + "+" + env.gitHashShort
				// 			println("Version of Build: ${env.VERSION}")

				// 			def binaryFileName = "${ProductFileName}-${ELECTRON_RELEASE_V}.dmg"
				// 			def binaryPath = sh(returnStdout: true, script: "find . -name '${binaryFileName}' | head -1").trim()
				// 			// Publish to artifactory
				// 			def server = Artifactory.server 'Bose-Artifactory'
				// 			def targetPath = String.format(ARTIFACTORY_TARGET, PATH_PART, "${ProductFileName}-${env.VERSION}.dmg")
				// 			def fileSpec = """{
				// 				"files": [
				// 					{
				// 					"pattern": "${binaryPath}",
				// 					"target": "${targetPath}"
				// 					}
				// 				]
				// 			}"""
				// 			println("fileSpec: ${fileSpec}")
				// 			server.upload spec:fileSpec

				// 		}
				// 	}
				// }
			}
		}
	}

	post {
		 always {
	            script {
	                fileContents = readFile "${env.WORKSPACE}/EmailRecipients"
	                //send notification to email
	               // if (fileContents) {
	               //     emailNotify(fileContents.replaceAll("\n", ","))
	               // }
	            }
	         }																																		
		
// 		success {
// 			script {
// 			  if( env.CHANGE_ID ) {
// 				githubNotify( "pro-peak-betacon-mac", "Build succeeded", "SUCCESS", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
// 			  }
// 			}
// 		}
// 		failure {
// 			script {
// 			  if( env.CHANGE_ID ) {
// 				githubNotify( "pro-peak-betacon-mac", "Build failed", "FAILED", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
// 			  }
// 			}
//         	}
// 		cleanup {
// 			retry(3){
// 			    cleanWs()
// 			}
// 		}
	}
}
