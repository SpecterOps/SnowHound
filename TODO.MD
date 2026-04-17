I'm really interested in integrations of all types. I may have to create the integrations explicitly so we can start to understand how they manifest.

- ACCOUNT -> SECURITY INTEGRATIONS
- API INTEGRATIONS
- FUNCTION / PROCEDURE -> EXTERNAL ACCESS INTEGRATIONS
- STAGE -> STORAGE INTEGRATION

I'm also interested in digging into functions and procedures more. They may have the keys to many of the attack primitives. Examples are EXTERNAL ACCESS INTEGRATIONS, SECRETS, and EXECUTE AS OWNER.

Validate how permissions work. Do schema objects require permissions to the database, schema, and object or can we assume requisite permission to the database and schema based on the existance of the object permissions?

I think there is an opportunity to show also how the ability to create objects can be useful for attackers:

- Create users / assign roles for backdoors
- Create function or procedure that uses a secret or api integration