trigger ExampleAccountTrigger on Account(before insert, after update) {
  Domain.triggerHandler(ExampleAccountDomain.class);
}