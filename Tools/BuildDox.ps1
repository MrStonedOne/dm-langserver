$bf = $Env:APPVEYOR_BUILD_FOLDER

$doxdir = "C:\tgsdox"

New-Item -Path $doxdir -ItemType directory

$publish_dox = (-not (Test-Path Env:APPVEYOR_PULL_REQUEST_NUMBER)) -and ("$Env:APPVEYOR_REPO_BRANCH" -eq "master")

if($publish_dox){
	$github_url = "github.com/$Env:APPVEYOR_REPO_NAME"
	echo "Cloning https://git@$github_url..."
	git clone -b gh-pages --single-branch "https://git@$github_url" "$doxdir" 2>$null
	rm -r "$doxdir\*"
	Add-Content "$bf\Tools\Doxyfile" "`nPROJECT_NUMBER = $version`nINPUT = $bf`nOUTPUT_DIRECTORY = $doxdir"
}else{
	Add-Content "$bf\Tools\Doxyfile" "`nPROJECT_NUMBER = $version`nINPUT = $bf`nOUTPUT_DIRECTORY = $doxdir"
}

doxygen.exe "$bf\Tools\Doxyfile"

if($publish_dox){
	cd $doxdir
	git config --global push.default simple
	git config user.name "tgstation-server"
	git config user.email "tgstation-server@tgstation13.org"
	echo '# THIS BRANCH IS AUTO GENERATED BY APPVEYOR CI' > README.md
	
	# Need to create a .nojekyll file to allow filenames starting with an underscore
	# to be seen on the gh-pages site. Therefore creating an empty .nojekyll file.
	echo "" > .nojekyll
	git add --all
	git commit -m "Deploy code docs to GitHub Pages for Appveyor build $Env:APPVEYOR_BUILD_NUMBER" -m "Commit: $Env:APPVEYOR_REPO_COMMIT"
	git push -f "https://$Env:repo_token@$github_url" 2>&1 | out-null
	$Env:repo_token = ""
	cd "$bf"
}
