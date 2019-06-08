@echo off 
SETLOCAL EnableDelayedExpansion 
 
::################################################################################### 
::#               																	# 
::# Filename:  getLoma.bat         													# 
::#               																	# 
::# Description:  Configures the LOMA dev env for SW ENG 							# 
::#               																	# 
::# History:            															# 
::#               																	# 
::# Date  		Note       										SW ENG  			# 
::# 20190522 	Initial Release     							BMD  				#
::# 20190608	Initial review of script before mods executed 	NGW					# 
::# 20190608	File Mod after New_Branch 						NGW					#
::#               																	# 
::################################################################################### 
 
::---------------- 
::-  VAR REGION  - 
::---------------- 
 
:: Err Message strings 
set errorMessage[000]=Failed to receive proper err code, review %log% and contact SIT OKC point of contact if additional support is required. 
set errorMessage[001]=GIT not found in PATH; validate existence and try again. 
set errorMessage[002]=Failed to create required BLDDIR for artifacts, contact SIT OKC point of contact for assistance. 
set errorMessage[003]=Failed to PUSHD into BLDDIR. 
set errorMessage[004]=---------- Required GIT branch unaccessible for repository: 
set errorMessage[005]=Failed to clone required Repository: 
set errorMessage[006]=Failed to locate build config file. 
set errorMessage[007]=Failed to find myTags file. 
set errorMessage[008]=Failed to find DEV branch in repo: 
set errorMessage[009]=Failed to create the required packages directory. 
set errorMessage[010]=Failed to move required directory:   
 
:: MISC Variables used during script 
set gitServerHTTP=http://wcld83001:7990/scm/loma 
set repos[0]=LOMA 
set repos[1]=agileObjects,antlr,asposeCells,asposeDiagram,asposeEmail,asposePDF,asposeSlidesNet,asposeWords,bootstrap,entityFramework,fontAwesomeToolkit,jquery,jsZip,kendo,knockouts,linq,microsoftJQuery,microsoftMVC 
set repos[2]=microsoftOwin,microsoftRazor,microsoftSignalR,microsoftTypeScript,microsoftWeb,modernizr,newtonSoftJSON,owin,respond,valueInjecter,webgrease 
set allRepos=%repos[0]% %repos[1]% %repos[2]% 
set cmdWindows=lomaDir,packagesDir,logTail 
set log=%CD%\buildLog.txt 
set myTags=%CD%\myTags 
set startDir=%CD% 
set lomaFQP=%startDir%\LOMA\packages 
set lomaBase=LOMA\packages 
set tailMyLog=%CD%\tailMyLog.bat 
set watchLomaDir=%CD%\watchLomaDir.bat 
set watchLomaPkgDir=%CD%\watchLomaPkgDir.bat 
set myBldStat=.bldStat 
set myForLoop=for /l %%%%t in (^) do ( 
set tempFiles=%tailMyLog%,%watchLomaDir%,%watchLomaPkgDir%,%myBldStat%,%myTags% 
 
::----------------- 
::-  MAIN REGION  - 
::----------------- 

:: Script sequence of subroutines being executed.
CALL :createRequiredFiles 
CALL :openCmdWindows 
CALL :validateBuildEnv 
CALL :cleanBldEnv 
CALL :processRepos 
CALL :extractArtifacts 
CALL :removeArtifacts 
 
goto:eof 
 
::----------------------- 
::-  SUBROUTINE REGION  - 
::----------------------- 
 
::###############################################################
::																#
::	Subroutine: openCmdWindows									#
::																#
::	Description:												#
::	Subroutine opens various windows to inform user of status	#
::	during script execution in addition to primary window.		#
::																#
::###############################################################
:openCmdWindows 
 
:: Open the CMD WINDOW showing DIR of the LOMA directory 
start "Displaying LOMA Dir Content" cmd /T:20 /K %watchLomaDir% 
 
:: Open the CMD Window showing DIR of the LOMA\packages DIRECTORY 
start "Displaying LOMA\packages Dir Content" cmd /T:30 /K %watchLomaPkgDir% 
 
:: Open the tail of the BuildLog.Txt file so user can track progress of environment configuration 
start "Executing 'tail' of buildLog.txt" cmd /t:40 /K %tailMyLog% 
 
goto:eof 

::###############################################################
::																#
::	Subroutine: displayHelp										#
::																#
::	Description:												#
::	Helper subroutine to display pre-defined err msgs to output	#
::	to user and log file when required for user interaction.	#
::																#
::###############################################################
:displayHelp 

if "%1"=="" ( 
		
		echo !errorMessage[000]! >> %log% 
		@echo: 
		echo !errorMessage[000]! 
		@echo: 
		echo Review %log% for all recorded script output. 
		@echo: 
		pause

) else (

		if "%2"=="" ( 
			
			echo !errorMessage[%1]! >> %log% 
			@echo: 
			echo !errorMessage[%1]! 
			@echo: 
			echo Review %log% for all recorded script output. 
			@echo: 
			pause
			
		) else ( 
			
			echo !errorMessage[%1]! %2 %3 >> %log% 
			@echo: 
			echo !errorMessage[%1]! %2 %3 
			@echo: 
			echo Review %log% for all recorded script output 
			@echo: 
			pause 

		)
		
)  
 
pause 
exit 
goto:eof 
 
::###############################################################
::																#
::	Subroutine: confirmDirDelete								#
::																#
::	Description:												#
::	Processes same as while loop, deleting the content			#
::	found in an existing \blddir directory on a local			#
::	dev machine being used for cloning new build struct			#
::																#
::###############################################################
:confirmDirDelete

if EXIST %1 (

	set myDir=%1 
	
	for /D %%d in (!myDir!\*) do ( 
		
		@echo: >> %log% 
		echo %%d found... >> %log% 
		
		if EXIST "%%d" ( 
			
			echo Attempting delete of %%d >> %log% 
			rmdir /s /q %%d >> %log% 2>&1 
			
			if "%errorlevel%"=="0" ( 
			
				echo Removal Successfully Completed... >> %log% 
			)
			
			:: Required time pause for directory to catch up with processing logic 
			timeout /t 1 /nobreak >nul 
		)
		
		echo ----- Attempting deletion of directory !myDir! ----- >> %log% 
		rmdir /s /q !myDir! >> %log% 2>&1 
		if "%errorlevel%"=="0" ( 
		echo ----- Removal Successfully Completed ----- >> %log% 

	)
	
	goto:confirmDirDelete !myDir! 

) 
 
@echo: >> %log% 
goto:eof 
 
::###########################################################################################
::																							#
::	Subroutine: cleanBldEnv																	#
::																							#
::	Description:																			#
::	Check to ensure local machine has the proper tools installed (E.g. GIT, etc.)			# 
::	Failure of any logic in subroutine prevents script from further processing				# 
::	and will subsequently call displayHelp for user notification of err found.				#
::																							#
::###########################################################################################
:validateBuildEnv 
 
@echo: 
echo Validating local build environment... 
echo **************************** Validating Local Build Environment ***************************** > %log% 
@echo: >> %log% 
 
:: Validate GIT installed 
git --version >> %log% 2>&1 
@echo: >> %log% 
 
if "%errorlevel%"=="0" ( 
	 
	 @echo: 
	 echo ----- GIT properly installed on local machine ----- >> %log% 

) else ( 
	 
	 CALL :displayHelp 001
	 
) 
 
@echo: >> %log% 
 
goto:eof 

::###########################################################################################
::																							#
::	Subroutine: cleanBldEnv																	#
::																							#
::	Description:																			#
::	Subroutine validates the build environment on local machine is valid and not stagnant	#
::	from previous build possible failures within this function could occur at re-creation	#
::	of build directory structure failure of any logic in subroutine prevents script for		#
::	further processing and will call displayHelp for user notification of available			#
::	corrective actions.																		#
::																							#
::########################################################################################### 
:cleanBldEnv 
 
echo Cleaning build environment... 
echo **************************** Checking for stagnant artifacts **************************** >> %log% 
@echo: >> %log%

if EXIST LOMA (

	echo Confirmed stagnant %CD%\LOMA exists, attempting removal... >> %log% 
	CALL :confirmDirDelete LOMA 

) else ( 
	
	@echo: 
	echo Stagnant LOMA directory not found >> %log% 
	@echo: >> %log% 

)

goto:eof 
 
::###########################################################################################
::																							#
::	Subroutine: processRepos																#
::																							#
::	Description:																			#
::	For loop to query remote GIT repos to validate branch exists; if not exit as failed		# 
::	if success - clone repo as required for product development efforts.					#
::	Failure of any logic in subroutine prevents script from further execution and will		#
::	call displayHelp for user notification of available corrective actions.					#
::																							#
::########################################################################################### 
:processRepos 
 
set branch=dev 
echo Validating BRANCH for required clone of repositories... 
echo **************************** Validating Repository Branch **************************** >> %log% 
 
:: Validate the DEV branch is available in every repo required for build 
for %%f in (%allRepos%) do ( 
 
	@echo: >> %log% 
	set branchFound=1 
	echo ----- Attempting validation of GIT Branch %branch% in %%f repository ----- >> %log% 
	git ls-remote --heads %gitServerHTTP%/%%f.git %branch% > %myTags% 
	echo Checked repo %%f >> %myTags% 
  
	if EXIST %myTags% (
	
		for /F "eol=: tokens=1,2" %%v in (%myTags%) do (
		
			set myTag=refs/heads/%branch% 
		
			if "%%w"=="!myTag!" ( 
				echo ----- Successfully validated BRANCH %branch% in %%f repository ----- >> %log% 
				set branchFound=0 
			)
			
		)
		
	) else ( 
		
		CALL :displayHelp 007
		
	) 
 
	:: Validate success of tag in repository 
	if "!branchFound!"=="1" ( 

		CALL :displayHelp 008 "%%f" 

	) 
)  
 
@echo: 
echo Cloning required repositories for local development and build... 
@echo: >> %log% 
echo **************************** Cloning LOMA Repositories **************************** >> %log% 
  
for %%a in (%allRepos%) do ( 
	
	@echo: >> %log% 
	
	if "%%a"=="LOMA" ( 

		:: Clone LOMA REPO from remote server to root blddir directory 
		git clone "%gitServerHTTP%/%%a.git" >> %log% 2>&1 
		
		if "%errorlevel%"=="0" ( 

			echo ----- Repository %%a Successfully Cloned ----- >> %log% 
			mkdir LOMA\packages >> %log% 2>&1 

		) else (
		
			:: Clone of REPO %%a failed 
			CALL :displayHelp 008 "%%a" 

		)
		
	) else ( 

		if EXIST LOMA\packages ( 
		
			PUSHD LOMA\packages >> %log% 2>&1 
			git clone "%gitServerHTTP%/%%a.git" >> %log% 2>&1 
		
			if "%errorlevel%"=="0" ( 
			
				echo ----- Repository %%a Successfully Cloned ----- >> %log% 
		
			) else ( 
			
				:: Clone of REPO %%a failed 
				CALL :displayHelp 008 "%%a"    
			)
		)

		:: popd back to original directory
		POPD
		
	)  
)  
 
goto:eof 

::#######################################################################################
::																						#
::	Subroutine: extractArtifacts														#
::																						#
::	Description:																		#
::	Dir/File structure instructions to prepare for development to be executed			#
::	Failure of any logic in subroutine prevents script from further execution and will  #
::	call displayHelp for user notification of available corrective actions. 			#
::																						#
::####################################################################################### 
:extractArtifacts 
 
@echo: 
echo Configuring build environment artifacts... 
@echo: >> %log% 
echo **************************** Configuring Build Directory **************************** >> %log% 
@echo: >> %log% 
  
:: Process the directories within the repos to create packages dir as expected 
if EXIST %lomaFQP% ( 
	
	for /d %%d in (%lomaBase%\*) do ( 
		
		CD %startDir%\%%d >> %log% 
       	
		:: Iterate through all avail dirs; move to parent directory 
		for /d %%e in (%startdir%\%%d\*) do ( 
			
			echo ##### Currently Processing %%d\ ##### >> %log% 
			move %%e %startDir%\%lomaBase% >nul 
			
			if "%errorlevel%"=="0" ( 
			
				echo ----- Successfully moved DIR ----- %%d >> %log% 
				@echo: >> %log% 
				timeout /t 1 /nobreak >nul 
			
			) else ( 
				
				CALL :displayHelp 010 %%e     
			
			) 
    
		) 
   
		:: Change back to origin directory 
		CD %startDir% >> %log% 2>&1 
		@echo: >> %log% 
     
	)
	
) 
 
goto:eof 
 
::#######################################################################################
::																						#
::	Subroutine: removeArtifacts															#
::																						#
::	Description:																		#
::	Dir/File structure instructions to remove unnecessary structure						#
::	Failure of any logic in subroutine prevents script from further execution and will  #
::	call displayHelp for user notification of available corrective actions.				#
::																						#
::#######################################################################################
:removeArtifacts 

@echo: 
echo Processing cleanup tasks for temporary files/folders... 
echo **************************** Processing CleanUp **************************** >> %log% 
@echo: >> %log% 
 
for %%a in (%allRepos%) do ( 
	
	echo ##### Working repo: %%a ##### >> %log% 
       
	if "%%a"=="LOMA" ( 
  
		echo ----- Processing %%a; do nothing ----- >> %log% 
		@echo: >> %log% 
   
	) else ( 
  
		if EXIST %lomaFQP%\%%a ( 
  
			CALL :confirmDirDelete %lomaFQP%\%%a  
   
		)   
	) 
) 
 
@echo: 
echo LOMA configuration successful, goodbye...  
echo ----- LOMA configuration successful, goodbye ----- >> %log% 
pause 

::#######################################################################################
::																						#
::	Subroutine: createRequiredFiles														#
::																						#
::	Description:																		#
::	Create temporary files needed to open command windows to keep user informed on 		#
::	the current status of the scripts execution.										#
::																						#
::#######################################################################################
:createRequiredFiles 
 
@echo: 
echo Creating Temp Files Needed... 
echo **************************** Creating Temporary Files Needed **************************** >> %log% 
@echo: >> %log% 
 
:: Create the .bat file to execute for tailing buildLog.txt 
if NOT EXIST %tailMyLog% ( 
  
	echo @echo off > %tailMyLog% 
	@echo: >> %tailMyLog% 
	echo for /l %%%%t in (^) do ( >> %tailMyLog% 
	@echo: >> %tailMyLog% 
	echo      cls >> %tailMyLog% 
	echo      echo buildLog.txt File Content >> %tailMyLog% 
	echo      echo ------------------------- >> %tailMyLog% 
	echo      type buildLog.txt >> %tailMyLog% 
	echo      timeout /t 5 >> %tailMyLog% 
	echo ^) >> %tailMyLog% 
	@echo: >> %tailMyLog% 
	echo pause >> %tailMyLog% 
 
	timeout /t 1 /nobreak >nul 

) 
 
:: Create the .bat file to execute for watching LOMA directory 
if NOT EXIST %watchLomaDir% ( 
	
	echo @echo off > %watchLomaDir% 
	@echo: >> %watchLomaDir% 
	echo for /l %%%%t in (^) do ( >> %watchLomaDir% 
	@echo: >> %watchLomaDir% 
	echo      cls >> %watchLomaDir% 
	echo      echo Current content of the LOMA directory >> %watchLomaDir% 
	echo      echo ------------------------------------- >> %watchLomaDir% 
	@echo: >> %watchLomaDir% 
	echo      dir LOMA >> %watchLomaDir% 
	echo      timeout /t 2 >> %watchLomaDir% 
	echo ^) >> %watchLomaDir% 
	@echo: >> %watchLomaDir% 
	echo      pause >> %watchLomaDir% 
 
	timeout /t 1 /nobreak >nul
	
) 
 
:: Create the .bat file to execute for watching LOMA\packages directory 
if NOT EXIST %watchLomaPkgDir% (

	echo @echo off > %watchLomaPkgDir% 
	@echo: >> %watchLomaPkgDir% 
	echo for /l %%%%t in (^) do ( >> %watchLomaPkgDir% 
	@echo: >> %watchLomaPkgDir% 
	echo      cls >> %watchLomaPkgDir% 
	echo      echo Current content of the LOMA\packages directory >> %watchLomaPkgDir% 
	echo      echo ---------------------------------------------- >> %watchLomaPkgDir% 
	echo      dir LOMA\packages >> %watchLomaPkgDir% 
	@echo: >> %watchLomaPkgDir% 
	echo      timeout /t 2 >> %watchLomaPkgDir% 
	echo ^) >> %watchLomaPkgDir% 
	@echo: >> %watchLomaPkgDir% 
	echo      pause >> %watchLomaPkgDir% 
 
	timeout /t 1 /nobreak >nul 

) 
 
:: Create the .bldStat file for watching to close windows automatically 
if NOT EXIST %myBldStat% ( 
	
	echo 1 > %myBldStat% 
	timeout /t 1 /nobreak >nul 

) 
 
goto:eof 
 
 
 
 
 

