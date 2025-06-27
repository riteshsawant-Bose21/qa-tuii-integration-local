#include "file_util.h"


int readFile(const std::string &fileName, std::string &getsFirstLine) {
  std::ifstream fd(fileName);

  if (!fd) {
    spdlog::error("[readFile] '{}' not found", fileName);
    return -1;
  }

  std::getline(fd, getsFirstLine);
  fd.close();

  return 0;
}

int writeFile(const std::string &fileName, const std::string &writeData){
  std::ofstream fd(fileName, std::ofstream::trunc);

  if (!fd) {
    spdlog::error("[writeFile] '{}' not found", fileName);
    return -1;
  }

  fd << writeData.c_str();
  fd.close();
  return 0;
}

int appendFile(const std::string &fileName, const std::string &writeData){
  std::ofstream fd(fileName, std::ios::app);

  if (!fd) {
    spdlog::error("[appendFile] '{}' not found", fileName);
    return -1;
  }

  fd << writeData.c_str();
  fd.close();
  return 0;
}

int deleteFile(const std::string &fileName) {
  if (std::remove(fileName.c_str()) != 0) {
    if (errno == ENOENT)
    {
      spdlog::debug("File has been already deleted: {}", fileName);
      return 0;
    }
    else
    {
      spdlog::error("Error deleting file {}: {}", fileName, std::strerror(errno));
      return -1;
    }
  }
  return 0;
}

// Make sure a file exists, return 0 if the file exits, or was created. 
// return -1 otherwise.
int createFile(const std::string &filePath)
{
  if (fileExists(filePath)) {
    return 0;
  }

  std::ofstream fOut(filePath.c_str());
  if (fOut.is_open()) {
    fOut.close();
    return 0;
  }
  else {
    spdlog::error("Unable to create file: {}", filePath);
    return -1;
  }
}

std::string getDateTimeString(){
  time_t now = time(0);
  char timestr [32];

  tm *tmp = localtime(&now);
  strftime(timestr,32,"%Y-%m-%d-%H-%M-%S",tmp);
  return timestr;
}

int tarFiles(const std::string &sourceFolder, const std::string &sourceFile, const std::string &destPath){
  std::string tarCmd = "tar -cf " + destPath + " -C " + sourceFolder + " " + sourceFile;
  return runSystemCommand(tarCmd);
}

int gZipFile(const std::string &destPath){
  std::string gzipCmd = "gzip -f " + destPath;
  return runSystemCommand(gzipCmd);
}

int moveFiles(const std::string &sourcePath, const std::string &destPath){
  std::string moveCmd = "mv " + sourcePath + " " + destPath;
  return runSystemCommand(moveCmd);
}

int unZipFiles(const std::string &sourcePath, const std::string &destFolder){
  std::string unZipCmd = "gzip -df " + sourcePath;
  std::string tarName = sourcePath.substr(0, sourcePath.length()-3);
  std::string unTarCmd = "tar -xf " + tarName + " -C " + destFolder;
  std::string rmTarCmd = "rm -f " + tarName;

  int result = runSystemCommand(unZipCmd);
  if(result == 0){
    result = runSystemCommand(unTarCmd);
    if(result == 0){
      result = runSystemCommand(rmTarCmd);
    }
  }
  return result;
}

int copyFiles(const std::string &sourcePath, const std::string &destPath){
  std::string copyCmd = "cp " + sourcePath + " " + destPath;
  return runSystemCommand(copyCmd);
}

int changeFileOwner(const std::string &fileName, const std::string &userName, const std::string &groupName){
  std::string changeOwnerCmd = "chown -R " + userName + ":" + groupName + " " + fileName;
  return runSystemCommand(changeOwnerCmd);
}

int changeFileMode(const std::string &fileName, const std::string &mode){
  std::string changeFileMode = "chmod -R " + mode + " " + fileName;
  return runSystemCommand(changeFileMode);
}

std::string escapeJsonCharacters(const std::string &strBase)
{
  std::string outputString;
  for (char ch : strBase) {
    if (ch == '\\' || ch == '\"') {
      outputString += '\\';
    }
    outputString += ch;
  }
  return outputString;
}

int runSystemCommand(const std::string &cmd)
{
    int result = system(cmd.c_str());
    if(result !=0) {
      spdlog::error("Command ({}) failed with error code : {}", cmd, result);
      return 1;
    }
    return 0;
}

