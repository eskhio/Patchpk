const fs = require('fs');
const fileName = process.argv[2];
const fnNameToPatch = "checkServerTrusted";
const fileContent = fs.readFileSync(fileName, 'utf8');
let before, fnToPatch, fnPatched, after;
function printOK(v) {
	green = "\x1B[32m"
	console.log(green + v + "\x1B[m")
}
function printNOK(v) {
	red = "\x1B[31m"
	console.log(red + v + "\x1B[m")
}
/**
 * @description Chunk the file's content into 3 parts
 * 1 - Everything before the fn to patch
 * 2 - The fn to patch
 * 3 - Everything after the function to patch
 */
function chunkFileContent() {
	var fileFnsRegex = "((?:.*\n)+)(\.method public checkServerTrusted.*(?:\n.*)+.*\.end method)\n+((?:.*\n)+)";
	var fileFns = fileContent.match(new RegExp(fileFnsRegex));
	before = fileFns[1]; // 1.. before
	fnToPatch = fileFns[2]; // 2.. fn to patch
	after = fileFns[3]; //3.. viva l'algerie
}
/**
 * @description Patch the looked-for function within the file
 */
function patchFunction() {
	// Patching the fn to bypass harmful instructions
	printNOK("Vanilla function:\n\t\t" + fnToPatch);
	fnPatched = fnToPatch.replace(/end annotation/, "end annotation\n\n   return-void");
	printOK("Patched function:\n\t\t" + fnPatched);
}
/**
 * @description Prevent to looked-for function within the file to be re-patched
 */
function preventRepatch() {
	// If the function has the pattern that we apply to make it harmless, it's already harmless
	fnAlreadyPatched = fnToPatch[2].match(/end annotation\n\n   return-void/);
	if (fnAlreadyPatched) {
		printOK("\tFound an already patched pattern: \n\t" + fnToPatch);
		printOK("\tAlready patched!");
		return true;
	}
}
chunkFileContent()
patchFunction()
// Replacing the old fn by the patched one
fs.writeFileSync(fileName, before + fnPatched + after);
