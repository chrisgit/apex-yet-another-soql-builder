Yet Another SOQL Builder
------------------------

The demo-soql-builder folder contains examples for 
- strongly typed soql builder 
- lose typed soql builder with two builders using visitor pattern

In some cases writing a SQL or SOQL builder can be useful, if you think about it you can encapsulate several behaviors
- deconstructs the SQL into component parts
- enables cross cutting concerns
- allows for security checks

Cons are
- SQL and SOQL are highly sophisticated statements with many syntax variation
- Overhead in writing, testing and maintaining a builder as it is not normally core to business
- Often results in an awkward predicate syntax that does not cover all SQL or SOQL syntaxes

Overall I'm not a fan of SQL or SOQL builders, although I present one here, please, please, please think first before writing one, honestly the world does not need another SQL or SOQL builder!

So why is this code here? Essentially I've seen many implimentations of SOQL builder quite often all code is contained in a single class. As an exercise I've take a little time out to experiment with a builder that separates the components of the query with the construction and building of the query. The implementation should be familiar as the qyery construction make use of the Visitor pattern.

## The Code
[ISoqlExpression](src/force-app/main/default/classes/soql-builder/ISoqlExpression.cls) - is the interface for supporting the visitor  
[ISoqlProjectionBuilder](src/force-app/main/default/classes/soql-builder/ISoqlProjectionBuilder.cls) - is the interface for the visitor, if extra behavior is required it can be added here  
[SoqlField](src/force-app/main/default/classes/soql-builder/SoqlField.cls) - a class to represent a single field in the query  
[SoqlFieldSet](src/force-app/main/default/classes/soql-builder/SoqlFieldSet.cls) - a class to represent a collection of fields, in Salesforce this will be a fieldset  
[SoqlProjectionBuilder](src/force-app/main/default/classes/soql-builder/SoqlProjectionBuilder.cls) - a concrete instance of a visitor, this one just navigates through the object graph and prints out the fields  
[SoqlProjectionBuilderWithLogic](src/force-app/main/default/classes/soql-builder/SoqlProjectionBuilderWithLogic.cls) - a concrete instance of a visitor, this one has basic field accessibility checks  
[SoqlQuery](src/force-app/main/default/classes/soql-builder/SoqlQuery.cls) - container for the entire query, only supports the projection and from  
[SoqlRelation](src/force-app/main/default/classes/soql-builder/SoqlRelation.cls) - a class to represent a custom relationship, something that will end in __r  
[SoqlSelectExpression](src/force-app/main/default/classes/soql-builder/SoqlSelectExpression.cls) - a class to store expressions  

The initial implimentation of the visitor pattern was intended to be simpler with common functionality stored in abstract classes but there seemed to be an issue in Apex with double dispatching to the correct method in the visitor.

## Implementation
There is a Fluent interface to build the SOQL. The Fluent interface for the query container accepts a single method `add` which takes a type of ISoqlExpression. However there is no reason why the component classes do not contain more behavior or the Fluent API more explicit about the type of component that can be added, for example `addField(...)`, `addRelation(...)`, `addFieldSet(...)` etc. 

In the case of the latter it is potentially easier to build the hierarchy of components as we can inject some context, for example knowing a field exists in a relationship; the `addRelation()` method constructs the field passing into it context of where it came from, arguably this will make the builders simpler but creates a stronger coupling between component and builder.

## Salesforce metadata
The builder here accepts relationship and fieldnames as STRINGS; not so bad but if you need to perform checks on the relationships or fieldnames to see if they exist or are accessible then the string representation of the relationship or fieldnames will need to be converted to something more concrete. Fortunately for us, Salesforce has a rich metadata system, I've taken the metadata classes and wrapped them with two other classes
- ObjectFactory - returns an instance of ObjectSchema for a Salesforce type 
- ObjectSchema - wraps some of the existing Salesforce metadata functionality

```
ObjectSchema schema = new ObjectFactory().getSchemaFor('Account');
System.Debug('***** Field ' + schema.getField('Name'));
System.Debug('***** Field accessible? ' + schema.getFieldDescription('Name').isAccessible());
List<Schema.FieldSetMember> fieldSetMemberList =  schema.getFieldSet('YourFieldSet');
for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
{
    system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()); //api name
    system.debug('Label ====>' + fieldSetMemberObj.getLabel());
    system.debug('Required ====>' + fieldSetMemberObj.getRequired());
    system.debug('DbRequired ====>' + fieldSetMemberObj.getDbRequired());
    system.debug('Type ====>' + fieldSetMemberObj.getType());   //type - STRING,PICKLIST
}
```

## Code Alternatives
While writing the code several other patterns came to mind, notably state machines, which can be used to add the SOQL components together or as part of builder.

If you are still keen on creating your own SOQL builder, go for it, it's fun but just be aware that there are a lot of scenarios to cover if you need the builder to handle all eventualities. Salesforce alone has different ways to join data together, below is a simple example

`select id, Name, (Select Id, Name from contacts), (Select Id, Name From Opportunities where Id='Your Opportunity Id') from Account`

Relationships can be problematic, a reference to another table can be polymorphic (that is links to different tables for different records).

`SELECT task.account.name, task.who.name, task.activitydate FROM task WHERE task.activitydate <= TODAY AND task.who.type = 'Contact' AND task.account.annualrevenue > 150000000 ORDER BY task.account.annualrevenue DESC`

Whatever you build a good place to start is get in and start to understand some of the [object basics](https://developer.salesforce.com/docs/atlas.en-us.224.0.object_reference.meta/object_reference/sforce_api_objects_concepts.htm)


## SOQL Builder Alternatives
From the Apex Enterprise patterns I really like the [Selector Layer](https://github.com/financialforcedev/df12-apex-enterprise-patterns#data-mapper-selector)
- Keeps retrieval of data consistent throughout the application
- Uses fieldnames rather than strings
- Handles related data, albeit with a little bit of work

As part of the Enterprise pattern libraries there is the [Query Factory](https://github.com/apex-enterprise-patterns/fflib-apex-common/blob/master/fflib/src/classes/fflib_QueryFactory.cls) but there is too much code for a single class, it's unclear what it's single responsibility is!


Note: This code was part of my Apex Playground repository but broken out into its own repository to make it easier to follow and maintain.