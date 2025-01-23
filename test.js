require(__dirname + "/browsie-script.js");

describe("BrowsieScript Parser API Test", function () {

  it("can load the parser", async function () {
    if (typeof BrowsieScript.parse !== "function") throw new Error("1");
  });

  it("can parse a simple JsonTyped string", async function () {
    [
      `@Protocol.of.wherever {}`,
      `@wherever {}`,
      `@file:///var/www/http {}`,
      `@http://example.org/some/path?some=data&some=more#and-section-too {}`,
      `@view-source:///kernel/settings?with=details&configured=properly#section-2 {}`,
      `@browsie://default/action/crud.users.insert.one {"name":"administrator","password":"administrator.123","email":"admin@admin.org"}`,
    ].forEach(s => {
      const ast = BrowsieScript.parse(s);
      console.log(ast);
    });
  });


  [
    `users+[{},{},{}]`,
    `users+[{{ Factory.user() }},{{ Factory.user() }},{{ Factory.user() }}]`,
    `users+[#1,#2,#3]`,
    `users={}`,
    `users:{{ it.name === "admin" }}={ password: "x" }`,
    `users-{{ it.name === "admin" }}`,
    `users:{{ it.name.startsWith("admin") }}? > $.filters.sort(_, "+name,-id") >> {{ const x1 }}`,
    `users:{{ it.name.startsWith("admin") }}? > $.filters.sort(_, "-id") >> {{ const x1 }}`,
    `users:#1? > sort(#2) >> {{ const x1 }}`,
    `resources+ @http://example.org/some/path?some=data&some=more#and-section-too {}`,
    `resources+ @view-source:///kernel/settings?with=details&configured=properly#section-2 {}`,
    `resources+ @browsie://default/action/crud.users.insert.one {name:"administrator",password:"administrator.123",email:"admin@admin.org"}`,
    `users:name="admin@admin.org"&email="admin@admin.org"&password="admin"?`,
    `users:name="admin@admin.org"|email="admin@admin.org"?`,
    `users:name="admin@admin.org"|email="admin@admin.org"? > $functions.stores["variable with spaces"].sort(_, 500)`,
    `users?`,
    `users+{}`,
    `users+{"name":"admin","password":"admin"}`,
    `users+[{},{},{}]`,
    `users={changed:true}`,
    `users:1={name:"admin changed"}`,
    `users:"admin"={name:"admin changed"}`,
    `users:id=1={name:"admin changed"}`,
    `users:name="admin" and password="admin"={name:"admin changed"}`,
    `users:"admin"?`,
    `users-1`,
    `users-"admin"`,
    `users-id=1`,
    `users-id=1`,
    `users?`,
    `users:1?`,
    `users:"admin"?`,
    `users:name="admin"?`,
    `users:name="admin" or email="admin"?`,
    `users:name="admin"|email="admin"?`,
    `users:name="admin" and email="admin"?`,
    `users:name="admin"&email="admin"?`,
    `users? > $.sort.by.props(_, "created_at", "name", "id")`,
    `users:(name="admin"|email="admin")&(id is not null)? > $.sort.by.props(_, "created_at", "name", "id")`,
    `users? * console.log`,
    `messages+{message:"Hello, world!"}`,
    `messages:1? * console.log`,
  ].forEach((s, si) => {
    it("can parse a simple BrowsieScript string of test " + si, async function () {
      try {
        const ast = BrowsieScript.parse(s);
        console.log(JSON.stringify(ast, null, 2));
      } catch (error) {
        console.log(error);
        console.log(s);
        error.message += " + Failed on test of: " + s;
        throw error;
      }
    });
  });

});