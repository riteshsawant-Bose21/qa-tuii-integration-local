#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import java.util.regex.Pattern
import JenkinsJobCleanup
import groovy.json.JsonOutput
def VERSION = ''
def JobCleanup = new JenkinsJobCleanup()

ARTIFACTORY_TARGET = "pro-fusion-local/Fusion-DSP/%s/%s/%s/%s"

pipeline {
	agent { label 'pro-fusion-container' }
	
	options {
		timeout(time: 2, unit: 'HOURS')
		skipDefaultCheckout()
	}
	environment {
	        buildDir="${env.WORKSPACE}"
		buildNumber="${env.BUILD_NUMBER}"
		VersionFile="src/VERSION"
	        SDK_DIR="/fusion-build-cache/bose/fusion/yocto-sdk/"
    	}
	
	stages {
		stage('Clone') {
			steps {
				script {
					def branch = env.CHANGE_BRANCH ?: env.BRANCH_NAME
					retry(3){
						checkout([$class: 'GitSCM',branches: [[name: "${branch}"]],
							  doGenerateSubmoduleConfigurations: false,
							  extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true, timeout: 30]],
							  userRemoteConfigs: [[credentialsId: '5801fa82-23a0-4402-868e-7ca5fa2c6638',
									       name: 'pro-mune-dsp',
									       url: 'https://github.com/BoseProfessional/pro-mune-dsp.git']]
							 ])
					}
					// Set github info in env. variable
					githubInfo()
				}
			}
		}
		stage('Check') {
			when {
				anyOf {
					changeRequest target: 'main'
					branch 'main'
					changeRequest target: 'DEVOPS-61'
					branch 'DEVOPS-61'
				}
			}
			stages {
				stage('Prepare') {
				    	environment {
                        			GIT_KEY = credentials('bosepro-auto-ssh')
                    			}
					steps {
						script {
						  if( env.CHANGE_ID ) {
							githubNotify( "Build-Fusion-DSP", "Stage: Prepare ...", "PENDING" )
				  		  }
						}
						sh'''
						    git submodule update --init --recursive
	  					    chmod +x ./Jenkins/SetVersionProperty.sh
	    					    
						'''
						
					}
				}
				
				stage('Build') {
					steps {
						script {
							if( env.CHANGE_ID ) {
								githubNotify( "Build-Fusion-DSP", "Stage: Build Fusion-DSP Application ...", "PENDING" )
				  		  	}
							env.gitHashShort=env.GIT_COMMIT.take(7).trim().toString()
		  					ver=sh(returnStdout:true, script: './Jenkins/SetVersionProperty.sh').trim()
	      						env.VERSION=ver
							println("buildDir: ${buildDir}")
							println("GIT_COMMIT: ${env.GIT_COMMIT}")
							println("VERSION: ${env.VERSION}")
							println("gitHashShort: ${env.gitHashShort}")
							println("ver: '${ver}'")
							sh """
							    source "$SDK_DIR"/environment-setup-cortexa53-crypto-poky-linux
						            cd "$buildDir"
						            python3 waf configure --platform=varmini
						            python3 waf build
						            ls -l build/
							"""
							}
						}
				}

				// stage('Package DSP build') {
				// }

				// stage('Artifactory') {
				// }
			}
		}
	}

	post {
		success {
			script {
			  if( env.CHANGE_ID ) {
				githubNotify( "Build-Fusion-DSP", "Build succeeded", "SUCCESS", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
			  }
			}
		}
		failure {
			script {
			  if( env.CHANGE_ID ) {
				githubNotify( "Build-Fusion-DSP", "Build failed", "FAILED", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
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
