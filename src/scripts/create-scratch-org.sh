# Create a scratch org and make it the default scratch org
sfdx force:org:create --setalias="apex-yet-another-soql-builder" --durationdays=7 --definitionfile="%~dp0/../config/project-scratch-def.json" --nonamespace --setdefaultusername
