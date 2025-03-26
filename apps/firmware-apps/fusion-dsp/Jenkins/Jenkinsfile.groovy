#!/usr/bin/env groovy

@Library(['ProJenkinsSharedLibrary']) _
import java.util.regex.Pattern
import JenkinsJobCleanup
import groovy.json.JsonOutput
def VERSION = ''
def JobCleanup = new JenkinsJobCleanup()

NEXUS_TARGET = "Fusion-DSP/%s/%s/%s/%s"

pipeline {
	agent { label 'pro-fusion-container' }
	
	options {
		timeout(time: 2, unit: 'HOURS')
		skipDefaultCheckout()
	}
	environment {
		NEXUS_URL = '10.100.109.38:8081'
		CREDENTIALS_ID = 'jenkins-artifact-deployer'
	    	buildDir="${env.WORKSPACE}"
		buildNumber="${env.BUILD_NUMBER}"
		BuildType="Continuous"
		VersionFile="src/VERSION"
	    	SDK_DIR="/fusion-build-cache/bose/fusion/yocto-sdk/"
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
		stage('Clone') {
			steps {
				script {
					env.branch = env.CHANGE_BRANCH ?: env.BRANCH_NAME
					retry(3){
						checkout([$class: 'GitSCM',branches: [[name: "${env.branch}"]],
							  doGenerateSubmoduleConfigurations: false,
							  extensions: [[$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true, timeout: 30]],
							  userRemoteConfigs: [[credentialsId: '5801fa82-23a0-4402-868e-7ca5fa2c6638',
									       name: 'fusion-dsp',
									       url: 'https://github.com/BoseProfessional/fusion-dsp.git']]
							 ])
					}
					// Set github info in env. variable
					githubInfo(env.branch)
				}
			}
		}
		stage('Check') {
			when {
				anyOf {
					changeRequest target: 'main'
					branch 'main'
				}
			}
			stages {
				stage('Prepare') {
				    	environment {
                        			GIT_KEY = credentials('bosepro-auto-ssh')
                    			}
					steps {
						script {
							githubNotify( "Build-Fusion-DSP", "Stage: Prepare ...", "PENDING" )
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
							githubNotify( "Build-Fusion-DSP", "Stage: Build Fusion-DSP Application ...", "PENDING" )
							env.gitHashShort=env.GIT_COMMIT.take(7).trim().toString()
		  					ver=sh(returnStdout:true, script: './Jenkins/SetVersionProperty.sh').trim()
	      						env.VERSION=ver
							println("buildDir: ${buildDir}")
							println("VERSION: ${env.VERSION}")
							println("gitHashShort: ${env.gitHashShort}")
							println("ver: '${ver}'")
							sh """
							    source "$SDK_DIR"/environment-setup-cortexa53-crypto-poky-linux
						            cd "$buildDir"
						            python3 waf configure --platform=varmini
						            python3 waf build
							"""
						}
					}
				}

				stage('Package DSP build') {
				    steps {
						script {
							githubNotify( "Build-Fusion-DSP", "Stage: Build Fusion-DSP Application ...", "PENDING" )
							sh """
						        python3 package.py
							"""
						}
					}
				}

				stage('Upload to Nexus repository') {
					steps {
    					script {
                            			EMBEDDED_PATH_PART=env.CHANGE_BRANCH ?: env.BRANCH_NAME
                            			def fileName = "fusion-dsp_*.tar.gz"
                            			def binaryPath = sh(returnStdout: true, script: "find . -name '${fileName}' | head -1").trim()
						def binaryFileName = sh(returnStdout: true, script: "basename -- '${binaryPath}'").trim()
						def artifacts = []
						// def targetPath = String.format(NEXUS_TARGET, env.BuildType, EMBEDDED_PATH_PART, env.VERSION, binaryFileName)
						def targetPath = String.format(NEXUS_TARGET, env.BuildType, EMBEDDED_PATH_PART)
						println("binaryPath: ${binaryPath}")
						println("binaryFileName: ${binaryFileName}")
    						}
					}
				}
			}
		}
    }

	post {
		success {
			script {
				githubNotify( "Build-Fusion-DSP", "Build succeeded", "SUCCESS", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
			}
		}
		failure {
			script {
				githubNotify( "Build-Fusion-DSP", "Build failed", "FAILED", "${env.JOB_URL}${env.BUILD_NUMBER}/display/redirect" )
			}
        	}
		cleanup {
			retry(3){
			    cleanWs()
			}
		}
	}
}
