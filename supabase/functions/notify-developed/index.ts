import { createClient } from "jsr:@supabase/supabase-js@2"
import { SignJWT, importPKCS8 } from "npm:jose@5"

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
)

const keyId = Deno.env.get("APNS_KEY_ID")!
const teamId = Deno.env.get("APNS_TEAM_ID")!
const bundleId = Deno.env.get("APNS_BUNDLE_ID")!
const host = Deno.env.get("APNS_HOST")!
const privateKey = await importPKCS8(Deno.env.get("APNS_PRIVATE_KEY")!, "ES256")

async function makeAPNsToken(): Promise<string> {
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey)
}

async function sendPush(deviceToken: string, jwt: string, title: string, body: string) {
  const res = await fetch(`https://${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
    },
    body: JSON.stringify({
      aps: { alert: { title, body }, sound: "default" },
    }),
  })
  if (!res.ok) {
    console.error(`APNs rejected ${deviceToken.slice(0, 8)}…: ${res.status}`, await res.text())
  }
}

Deno.serve(async (req) => {
  const payload = await req.json()          // read the JSON the webhook sent
  const roll = payload.record               // the row after the change
  const oldRoll = payload.old_record        // the row before the change

  // only continue if the roll JUST became developed
  if (roll.status !== "developed" || oldRoll?.status === "developed") {
    return new Response("skipped: not newly developed")
  }

   const { data: fresh } = await supabase
    .from("rolls")
    .select("status")
    .eq("id", roll.id)
    .single()
  if (fresh?.status !== "developed") {
    return new Response("skipped: roll is not developed")
  }
  
  const { data: members, error: membersError } = await supabase
    .from("roll_members")
    .select("user_id")
    .eq("roll_id", roll.id)
  
    if (membersError) {
      console.error("Failed to load members:", membersError)
      return new Response("error", {status: 500}) 
    }
    const userIds = members.map((m) => m.user_id)

    const { data: tokens, error: tokensError} = await supabase
      .from("push_tokens")
      .select("token")
      .in("user_id", userIds)

    if (tokensError) {
      console.error("Failed to load tokens:", tokensError)
      return new Response("error", {status: 500})
    }

     const jwt = await makeAPNsToken()
      for (const t of tokens) {
        await sendPush(t.token, jwt, `🎞️ ${roll.name} has developed!`, "Open TwentyFour to see everyone's photos.")
      }


    console.log(`Roll ${roll.name}: ${userIds.length} member(s), ${tokens.length} device(s) to notify`)
    return new Response("ok")
    
})
