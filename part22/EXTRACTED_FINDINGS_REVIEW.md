## Part22_Step13_PE_Sirius_lib_power_Import_Trace_Evidence.zip / evidence/README_PART22_STEP13.md

# Part 22 — Step 13 evidence package

**Scope:** PE component instance accessor, the two `siriusInstance` structures, component Table A/Table B imports, and the `lib_power` acquire/PE_POLICY caller path. Static analysis only.

## Principal results

1. The PE component instance accessor at `0xE070AEC8` returns `0xC1906644`, exactly `0xC190662C + 0x18`. This is a concrete address inside the previously identified Sirius singleton, not a string inference.
2. The rtpadapter ROMFS object contains two adjacent initializer entries which construct separate structures carrying the exact key `siriusInstance`:
   - provider-side named object: global `0xC1D5E880`, accessor returns slot address `0xC1D5E884`;
   - lib_power descriptor: global `0xC1D62B4C`, accessor returns slot address `0xC1D62B50`.
3. The PE instance accessor and these matching name-keyed structures are consistent with a PE/Sirius instance being exposed to the lib_power component through a generic named dependency resolver. **The resolver call and pointer transfer have not been recovered.**
4. The component import table provides a useful negative result. `lib_power` advertises Table A keys `0x1141F` and `0xD68CDF`. The `pe`, `pe_events` and `pen` Table B records do not contain either key. `lib_digital_sensor` Table B entry 3 does contain `0x1141F`.
5. The corrected power-client table still maps `POWER_CLIENT_PE_POLICY` to `0x00400000`. No reviewed direct call site to shared acquire helper `0xE093DC50` passes that fixed mask. The lib_power acquire wrapper `0xE093E2A0` has no direct BL/B.W callers in the retained `.srtext` image; indirect calls remain possible.
6. A separate CROM `.cromsrtext` image and small setup/startup sections were checked. They did not reveal the missing resolver. The main LBI `.startup_text` and `.load_text` sections remain a future target.

## What this does not prove

- It does not prove that the runtime resolver populates `0xC1D5E884` or `0xC1D62B50` with `0xC1906644`.
- It does not prove that PE directly imports the `lib_power` component through its numeric Table B records.
- It does not prove that PE requests `POWER_CLIENT_PE_POLICY`, or that the power path causes `rtp_manager.block_print`, `unblock_print`, or the PE blocked-state writer to execute.
- The unresolved indirect call near `0xE0837994` places `0x00400000` on the stack before a virtual call with different register arguments. It is not counted as a lib_power acquire call without resolving its vtable target and ABI.

## Evidence files

- `romfs_objs_rebuilt.bin`: complete reconstructed ROMFS object section used to parse exact component headers, Table A/B records, initializer pointers and string keys.
- `srtext_rebuilt.bin`: reconstructed executable section used to verify the PE accessor, registry constructors/accessors and lib_power wrapper instruction bytes.
- `cromsrtext.bin`, `setup_text.bin`, `romstartup_text.bin`: exact FHX sections examined in the secondary-image check.
- `component_dependency_crosswalk.txt`: decoded PE, pe_events, pen, lib_power and lib_digital_sensor component headers and table entries.
- `PE_Sirius_lib_power_disassembly.txt`: focused disassembly excerpts, including the unresolved `0x00400000` virtual-call setup.
- `direct_call_xref_audit.txt`, `power_acquire_callsite_audit.txt`, `power_client_name_table.txt`: prior full-disassembly audits and the corrected client name list.
- `SOURCE_INPUTS.txt`: sizes and SHA-256 identities of the upstream LBI, FHX, section and disassembly inputs.
- `verify_part22_step13.py`, `verification_output.txt`: reproducible structural and binary checks.
- `Previous_Revision99_Addendum.docx`, `Previous_Step12_Evidence_Package.zip`: prior addendum/evidence retained for continuity.
- `Revision100` DOCX and its QA PDF: current cumulative Steps 11–13 addendum.

## Verification

Run from the extracted package directory:

```bash
python verify_part22_step13.py
```

The verifier passed **102/102 checks**. It checks exact section hashes, component header/table boundaries, key relationships, function-pointer records, machine-code bytes, the PE singleton accessor calculation, CROM raw-reference scan, and preserved direct-call-audit counts. The complete original LBI and FHX source binaries remain separately identified by hash in `SOURCE_INPUTS.txt` and in the earlier Part 1 evidence package.

## Operational boundary

No printer connection, network request, firmware write, updater execution, debug activation, print/scan job or device-state change was performed in Step 13.



## Part22_Step14_Startup_Load_and_00400000_Trace_Evidence.zip / README_PART22_STEP14.md

# HP DeskJet 2855e firmware investigation - Part 22, Step 14

## Scope

Offline static analysis only. This step followed the FHX main-image `.startup_text`, `.startup_rodata`, `.load_text` and `.load_rodata` section descriptors, then re-examined the unresolved virtual call at `.srtext` address `0xE0837994` and its `0x00400000` stack argument.

No printer communication, firmware update, firmware write, reset, debug activation, print/scan job, or device-state change was performed.

## Main results

1. The FHX directory at payload offset `0xBD8` describes a contiguous startup/load image based at `0xE0230000`. The exact section slices and hashes are in `sections/section_inventory.json`.
2. `.startup_text` (604 bytes) decodes as ARM/A32 processor initialization. It performs CP15 cache, TLB, translation-table and system-control operations. Its branch-reached code in `.startup_rodata` continues the low-level mapping/exception setup. No named component/dependency resolver was recovered in the decoded path.
3. `.load_text` is correctly located at payload offset `0x13380`, VMA `0xE0243380`, size `0x2A3C`. It does not decode coherently in ARM/A32 or Thumb probes. Its transform/packing is unknown; it is not claimed to be encrypted.
4. The `0xE0837994` virtual call uses `r1=0x23`, `r2=&"/reprint"`, `r3=0x19000`, and stack argument 0 `0x00400000`. Nearby operations use path-like strings (`/system`, `/tmp`, `/shm`, `/copy`, `/ishare`, `/photo`, `/uithm`, `/reprint`). The concrete vtable method is unknown, but this call does not match the known `lib_power` acquire ABI. The earlier Step 13 `0x00400000` lead is therefore reclassified as not evidence of `POWER_CLIENT_PE_POLICY` use.
5. The full `.srtext` disassembly records 14 references to acquire helper `0xE093DC50` and 12 to release helper `0xE093DC68`. The only direct BL reference to `0xE0837848` is internal at `0xE08379CE`; the runtime vtable target remains unresolved.

## Important interpretation limits

- The branch-reached code examined in `.startup_rodata` establishes that this section is mixed code/data in relevant regions; the whole section was not assigned one instruction mode.
- Failed ARM/Thumb disassembly of `.load_text` does not prove encryption or absence of code. It means the required transform is not recovered.
- The three raw `0x00400000` byte-sequence occurrences in `.load_text` are all unaligned offsets (`0x110E`, `0x1C5E`, `0x1C7F`). They are not evidence of a literal word or active power-client request.
- No path from these findings to `rtp_manager.block_print`, `unblock_print`, or the PE blocked-state writer was established.

## Reproduction

The evidence archive includes `fhx_secure_payload_rebuilt.bin` and `srtext_rebuilt.bin` used for the extraction and call-site trace.

```bash
python extract_fhx_sections_step14.py
python verify_part22_step14.py
```

The `.load_text` ARM/Thumb probes are preserved in `load_text_arm_probe.dis` and `load_text_thumb_probe.dis`. The disassembly generator is `generate_load_text_probes.sh`; it expects `clang` and `llvm-objdump`.

The full `.srtext` disassembly generated for the cross-reference audit was large and is not duplicated in this ZIP. Its source bytes are included as `srtext_rebuilt.bin`; the exact relevant xref lines and the `0xE0837994` function context are preserved in `srtext_direct_xref_audit.txt` and `indirect_00400000_context.disasm.txt`.

## Findings document

`HP_DeskJet_2855e_Independent_Printing_Scanning_Investigation_Revision101_Part22_Step14_Startup_Load_and_00400000_Trace_Addendum.docx` extends the standalone Revision 100 addendum. It is not merged into the earlier 194-page cumulative report.

PDF render is included for convenience. Revision 101 contains 20 pages: its first 15 pages are pixel-identical to Revision 100 at 30 dpi; the five new pages were visually inspected at 120 dpi.



## Part22_Step15_PE_Event_Producer_and_Client_Audit_Evidence.zip / evidence/STEP15_FINDINGS.txt

PART 22 - STEP 15 FINDINGS

1. Seven components have array-D records for id 0x0001347F:
   jm_copy, job_tracker, pe, quiet_mode_cntrl, rest_fw_update, rtp_manager, smpw.
   Every one uses the same context pointer 0xE09680D9.

2. 0xE09680D9 points to wrapper 0xE09680D8. The wrapper loads descriptor 0xE0D421E0 and forwards it to generic helper 0xE066BAA8 / 0xE066B590. That descriptor contains the exact strings ipc_evt_prod_pe_event, IpcEvtProdPeEvent, event_id, and event. This makes 0x1347F a named PE event-producer subscription/registration path, rather than an unexplained numeric id. The event id to actual runtime payload publication is not fully recovered.

3. The seven callbacks use a common envelope: they access a nested object at event-context +0x14 and inspect a type value at nested +0x0C. Each subscriber handles different values:
   jm_copy: 0x1A, 0x42
   job_tracker: 0x1A, 0x16
   pe: 0x3A, 0x44, 0x02, 0x6C
   quiet_mode_cntrl: 0x89, 0x02
   rest_fw_update: 0x7B
   rtp_manager: 0x1A, 0x50, 0xE9
   smpw: 0x8B, 0x8C

4. PE handler 0xE070E980: type 0x3A adds a pointer to 0xC1906AE4[index] (index bounded below 0xB5); type 0x44 sets pointer at 0xC1906DB8; type 0x02 removes entries / clears the pointer; type 0x6C sets byte 0xC1906F5C. That byte is read by PE method 0xE070E568, which resolves/holds a shared object through 0xC1909FA8 and stores a related pointer at 0xC1906F60. The same flag is set during PE initialization by E070FBF6 -> E070EBF8. Treat it as an internal PE lifecycle latch, not as DSID_PRINT_ENGINE_BLOCKED or a print-block control.

5. Full direct lib_power acquire call audit: all statically resolved calls in .srtext use MECH, PEN, UDW, OPT_SENSOR, SCAN, SYS, or BOARD. None passes PE_POLICY mask 0x00400000. The exported lib_power wrapper may still be invoked indirectly by code outside this call graph; do not claim absolute absence.

6. Interpretation: this is the clearest current architectural bridge between PE and RTP. Both are subscribers to the same named PE-event producer, alongside job tracking, copy, quiet-mode, firmware-update, and SMPW components. It is a broadcast with typed payloads, not proof that the subscription alert or blocked-print control is emitted through it.

7. Still unresolved: the actual callsite that publishes the PE event; payload type corresponding to print-engine blocked state; runtime handoff to RTP slot 12; and the link between subscribedPagesOutAccountProblem (alert 66220) and block_print / PE blocked-state writer.

Do not equate PE latch byte 0xC1906F5C with DSID_PRINT_ENGINE_BLOCKED (0x12196); that equivalence is not established. The named PE event producer association is static metadata linkage; runtime publication and payload semantics remain unresolved.



## Part22_Step16_PE_Events_Publisher_Registration_Trace_Evidence.zip / evidence/STEP16_FINDINGS.txt

PART 22 — STEP 16 FINDINGS
==========================

Golden architectural finding
-----------------------------
The PE event publisher callback registration path is now statically connected to the named `pe_events` component and to the event-emission site for ID 0x0001347F.

1. pe_events component metadata
-------------------------------
The standard component header at ROMFS VMA 0xE0B33A98 is labeled `pe_events` (label pointer 0xE0B33BC8). Its metadata callback is Thumb pointer 0xE0712189 (code 0xE0712188), which returns 0xE0B33A3C. Its instance accessor is Thumb pointer 0xE0713E69 (code 0xE0713E68). The header has one Array C record at 0xE0B33BD4 with words (0x0000052C, 0x0001347F), and its Array D count is zero.

The Array C semantics remain intentionally neutral; however, this component record carries the same ID that the emitter code publishes and seven other components subscribe to.

2. Registered publisher callback setter
---------------------------------------
The ROMFS object block immediately preceding the pe_events header contains a Thumb-tagged function pointer at 0xE0B33A6C: 0xE0712199. Its target code at 0xE0712198 performs:
  MOVW r0, #0xA144
  MOVT r0, #0xC190
  STR  r1, [r0]
  BX   lr

This stores the caller-supplied function pointer (r1) into global callback slot 0xC190A144. The exact runtime caller and value supplied in r1 remain unresolved. The retained full .srtext disassembly has no direct BL/BLX/B.W caller to 0xE0712198; the ROMFS pointer provides the observed indirect registration route.

3. Publisher callback is consumed by the event relay
----------------------------------------------------
The PE relay at 0xE07126B8 reads global root 0xC1915A6C and resolves a virtual interface using key 0x01011570. The adjacent ROMFS metadata names `pe_events.list`, contains key 0x00011570, and points to the label `DSID_PE_EVENT_ID_NOTIFY`. The low 24 bits of runtime key 0x01011570 match; the leading 0x01 byte is an additional runtime qualifier whose semantics are not independently decoded.

The relay next reads 0xC190A144 and skips publishing if it is null. If non-null, it builds a stack event envelope from the ROMFS base descriptor at 0xE0D421C8, stores its event data fields, and calls the function pointer with r0=0x0001347F and r1 pointing to the envelope. This is the first direct static event-publication site recovered for 0x1347F.

The pe_events instance accessor at 0xE0713E68 initializes [0xC1915A6C] to 0xC1915A70 and returns 0xC1915A7C. This is consistent with the same instance root that the relay reads; the component's full object construction and runtime resolver invocation are not recovered.

4. Subscriber side
------------------
Seven component D records subscribe to ID 0x0001347F and share context pointer 0xE09680D9: jm_copy, job_tracker, pe, quiet_mode_cntrl, rest_fw_update, rtp_manager, and smpw. Their callbacks are component-specific and were documented in Step 15.

5. Interpretation boundary
--------------------------
Confirmed: pe_events metadata carries ID 0x1347F; a ROMFS-registered setter writes the publisher function pointer into C190A144; the PE relay consumes that pointer and calls it with event ID 0x1347F; seven subscribers register for the same event.

Not confirmed: who calls the setter; which function address is passed as r1; runtime delivery; which payload subtype corresponds to print admission or a subscription block; any link to alert 66220, DSID_PRINT_ENGINE_BLOCKED (0x12196), rtp_manager.block_print (0xE07C1211), or unblock_print (0xE07C1219).

No printer interaction, network operation, firmware write, reset, flash, print job, or scan job was performed.



## Part22_Step17_SiriusInstance_Event_Envelope_and_Registry_Trace_Evidence.zip / evidence/STEP17_FINDINGS.txt

PART 22 — STEP 17 FINDINGS
==========================

Golden architectural finding
-----------------------------
The callback consumed by the PE event relay is a field in a separately initialized, named `siriusInstance` object at 0xC190A128. The PE relay uses that field as an optional callback for a typed 24-byte `IpcEvtProdPeEvent` envelope. A separate 32-entry object registry at 0xC190A148 is still processed after the optional external callback path.

1. Named object and callback field
----------------------------------
The ROMFS string at 0xE0B33984 is exactly `siriusInstance`.

The ROMFS-exposed initializer entry at 0xE0B33A38 is Thumb pointer 0xE07120D1 (code 0xE07120D0/0xE07120D8 sequence; the actual initializer body begins at 0xE07120D8). At 0xE07120D8 the code:
  - constructs r1 = 0xE0B33984 (`siriusInstance` string pointer),
  - constructs r0 = 0xC190A128,
  - tail-branches to 0xE0711FF0.

The initializer at 0xE0711FF0 writes the following words beginning at 0xC190A128:
  +0x00 = 0xE0B339D8
  +0x04 = 0xE0B33A18
  +0x08 = 0
  +0x0C = 0
  +0x10 = 0
  +0x14 = 0
  +0x18 = 0xE0B33984 (`siriusInstance`)

The setter at 0xE0712198 writes incoming r1 to 0xC190A144. This address is exactly 0xC190A128 + 0x1C, the next word after the initialized name field. A separate accessor at 0xE0712050 returns 0xC190A128.

This proves the callback slot is a field adjacent to the named `siriusInstance` object state, rather than an unrelated global variable. The static image still does not show the runtime caller of the setter or the actual function value supplied in r1.

2. Typed IPC event envelope
---------------------------
The event relay at 0xE07126B8 reads 0xC190A144. If the slot is non-null, it calls 0xE09680B0 with destination sp+8. That helper copies 24 bytes (six words) from descriptor base 0xE0D421C8 into the destination.

The descriptor at 0xE0D421C8 points to metadata at 0xE0D421E0, which names:
  - `ipc_evt_prod_pe_event`
  - `IpcEvtProdPeEvent`
  - object size 0x18 (24 bytes)
  - two named fields: `event_id` and `event`

Before the callback, the relay writes three words at stack offsets sp+0x14, sp+0x18 and sp+0x1C (values 1, r4 and r5). It then calls the callback from 0xC190A144 with r0 = 0x0001347F and r1 = sp+8, the constructed event envelope.

Interpretation: the callback slot is used as the external notification sink for a typed IPC PE-event object. The descriptor establishes the class/schema and field names; it does not reveal the runtime callback implementation or prove transport delivery to an external process/device.

3. Optional external callback and 32-entry object registry
----------------------------------------------------------
At 0xE071274E the relay tests the callback pointer at 0xC190A144. If null, it skips event-envelope construction and the callback invocation and branches to 0xE071276E.

The code after that branch still reaches a loop at 0xE0712778. It computes the registry base as 0xC190A148 (= 0xC190A128 + 0x20), uses record stride 0x5C8, and iterates indices 0 through 31 (limit 0x20). On a matching entry it checks per-entry fields and may execute cleanup helpers at 0xE07121A8 / 0xE0712268.

A separate registration/scan routine at 0xE0712238 also loops to the same 32-entry limit and uses the same base and 0x5C8 stride. These observations establish a 32-slot object/observer registry associated with the named object. They do not prove that the seven component D subscribers from Step 15 are the same records, nor that the loop broadcasts every event to all slots.

4. Connection to prior steps
----------------------------
Step 15 recovered seven component D-record subscribers for event ID 0x1347F, all sharing context 0xE09680D9 and the `IpcEvtProdPeEvent` schema association.
Step 16 tied the event emitter to the `pe_events` component record and to the callback setter at 0xE0712198.
Step 17 now ties the callback storage to the named `siriusInstance` object and confirms the emitted object is a typed `IpcEvtProdPeEvent` envelope. The local 32-entry registry is an additional object-management structure; its relationship to the seven D-record callbacks remains unproven.

5. Interpretation boundary
---------------------------
Confirmed:
  - 0xC190A128 is the base populated by the ROMFS-exposed initializer sequence with a `siriusInstance` name pointer at +0x18.
  - 0xC190A144 is +0x1C in that object and is written by 0xE0712198.
  - 0xE0712050 returns the same base 0xC190A128.
  - 0xE07126B8 consumes the callback slot and, when non-null, passes a 24-byte IpcEvtProdPeEvent envelope with outer event ID 0x1347F.
  - A 32-entry registry at 0xC190A148 is scanned independently of the optional callback branch.

Not confirmed:
  - The runtime caller of 0xE0712198 or the exact callback address passed in r1.
  - Whether the callback performs local IPC only, a broader event service notification, or another operation.
  - Runtime delivery to any subscriber or remote endpoint.
  - Any mapping from event subtypes to alert 66220, DSID_PRINT_ENGINE_BLOCKED (0x12196), RTP block_print, or unblock_print.
  - Whether the 32-entry registry is populated from the seven D records or another registration mechanism.

No printer interaction, network operation, firmware modification, flash, reset, print job, or scan job was performed. All Step 17 findings are static.

Next bounded target
-------------------
If continuing, prioritize the code that populates the function pointer in r1 for the metadata-exposed setter, and the code that maps the seven D-record callbacks into the runtime 32-entry object registry. Do not repeat broad string scans or assume the two registries are equivalent without an explicit data/control edge.



## Part22_Step19_PE_Wait_For_CanPrint_Nonzero_Condition_Registration_Evidence.zip / evidence/STEP19_FINDINGS.txt

PART 22 / STEP 19 - PE WAIT-FOR-CANPRINT NONZERO CONDITION REGISTRATION

Golden result
-------------
The in-image nonzero-token registration caller missed by the earlier direct-call audit is in the pe_wait_for_canprint component. Its method-table entry at ROMFS 0xE0B39708 points to Thumb function 0xE07269F9 (code 0xE07269F8), which branches to 0xE07268A8. That function calls the siriusInstance vtable slot +0x08 with:
  event/context object = 0xC192F06C
  context identifier   = 0x00002802
  condition token      = 0x00000001
  callback             = 0xE0726850 (Thumb pointer 0xE0726851)
The siriusInstance vtable at 0xE0B3412C has slot +0x08 = 0xE0713E81 (code 0xE0713E80). That adapter forwards the arguments into the shared relay 0xE07126B8. The relay stores the context argument at record +0x5B0 and token 1 at +0x5B8.

Correction to Step 18
---------------------
Step 18 described record +0x5B0 as an evaluator-object pointer consumed by the aggregate. Direct disassembly of the aggregate scan at 0xE0712378 does not support that description. The scan reads the registration ID at +0x00 and token at +0x5B8; it does not load +0x5B0. It then queries the shared provider at siriusInstance +0x18 via virtual slots +0x54 and +0x58, passing the token. The +0x5B0 value is retained caller context; its further use by other paths is not established here.

Shared service binding
----------------------
The siriusInstance service setter at 0xE07140D0 maps service ID 0x0005742E to object field +0x18. The aggregate reads precisely that field before calling virtual slots +0x54 and +0x58.
The pe_wait_for_canprint service setter at 0xE07269B0 maps the same service ID 0x0005742E to its own field +0x10. Its code at 0xE0726768 uses this provider's vtable slot +0x08 to subscribe to the literal key "wait_for_canprint", event/type value 0x3C, and flags/arguments 1,1; it stores the returned handle at 0xC192F064. The method at 0xE0726798 uses the same provider's vtable slot +0x10 with that handle to unregister.

This establishes that pe_wait_for_canprint and the siriusInstance aggregate use fields bound under the same service interface ID 0x5742E. It strongly connects the named wait-for-canprint condition path with the service interface the aggregate uses to test token 1. The two fields may resolve to the same provider instance, but pointer equality is not established by these static setter traces. It does not establish the concrete provider class name or prove that token 1 was active during the user's failed print job.

Additional callback behavior
----------------------------
The callback passed by pe_wait_for_canprint is code 0xE0726850. It accepts event/state values 0x10, 0x1A, 0x87, and 0x90 and branches into the wait/subscription state-management helpers. Their precise product semantics are not assigned here without a named enum crosswalk.

Established
-----------
- A statically identified in-image caller supplies nonzero condition token 1 through a virtual siriusInstance call.
- The call originates in the pe_wait_for_canprint component method table.
- The common relay records token 1 at +0x5B8.
- The aggregate scans +0x5B8 and evaluates it through the provider at siriusInstance +0x18.
- Service ID 0x5742E is bound to siriusInstance +0x18 and pe_wait_for_canprint +0x10.
- pe_wait_for_canprint uses that service to subscribe/unsubscribe to "wait_for_canprint".

Not established
---------------
- Whether the two injected fields for service ID 0x5742E resolve to the same runtime pointer or separate instances implementing the same service interface.
- That the relevant method-table entry actually executed on the user's printer.
- That token 1 was active at the time of the failed Print-Job.
- The provider's concrete implementation class/constructor behind service ID 0x5742E.
- The exact meaning of context identifier 0x2802 and callback state values 0x10/0x1A/0x87/0x90.
- A direct causal link from Instant Ink/account alert 66220, RTP block_print/unblock_print, or the WSCN scanner event subsystem to this condition.

Scope
-----
Static firmware analysis only. No printer communication, runtime memory capture, firmware modification, print attempt, or scan attempt was performed.



## Part22_Step20_PE_Wait_For_CanPrint_Readiness_State_Machine_Evidence.zip / evidence/STEP20_FINDINGS.txt

PART 22 / STEP 20 - PE WAIT-FOR-CANPRINT READINESS AND SUBSCRIPTION STATE MACHINE

Golden result
-------------
The pe_wait_for_canprint component is not a single-condition boolean check. Its service setter at 0xE07269B0 accepts four interface IDs and stores them in separate fields:
  0x0038948E  -> object +0x04
  0x0096BF7A  -> object +0x08
  0x000A701E  -> object +0x0C (siriusInstance)
  0x0005742E  -> object +0x10
The high-order zeros above are shown only for readability; the exact 32-bit values are 0x0038948E, 0x0096BF7A, 0x000A701E, and 0x0005742E.

Separate status query and wait subscription
--------------------------------------------
Function 0xE07267B8 uses the object field +0x04 (service ID 0x0038948E). It calls that provider's virtual method at vtable offset +0x08 with a 0xD0-byte stack result area. It then checks the word at result offset +0x8C and the provider's return value. Subject to the C192F068 latch being nonzero, the helper returns 1 exactly when:
  result[+0x8C] != 0 AND provider return value == 0.
Otherwise it returns 0.
The field +0x08 / service ID 0x0096BF7A is accepted by the setter, but no direct use was established in the PE Wait callback path examined here.

Function 0xE0726768 uses the separate field +0x10 (service ID 0x0005742E). It calls provider vtable +0x08 with:
  key string: "wait_for_canprint"
  r2: 0
  r3: 0x3C
  stack values: 1, 1
The returned handle is stored at 0xC192F064. Function 0xE0726798 calls the same provider's vtable +0x10 with that handle to unregister.
Thus the component has a distinct status-query provider (0x0038948E) and a distinct event subscription provider (0x0005742E).

Callback state machine
----------------------
The callback passed through the token-1 registration is code 0xE0726850. It handles four exact selector values:
  0x10: call status predicate 0xE07267B8; if false, subscribe to "wait_for_canprint" via 0xE0726768 and return 2; if true, return 1 without subscribing.
  0x1A: set word 0xC192F068 to 1; call unsubscribe via 0xE0726798; only if that call returns nonzero, re-run the status predicate; if the predicate is true, invoke cleanup helper 0xE0726808; return 1.
  0x87 and 0x90: call unsubscribe; only if that call returns nonzero, re-run the status predicate; if the predicate is true, invoke cleanup helper 0xE0726808; return 1.
  other values: return 1.
The meanings of these selector numbers are not assigned without a matching named enum. Their control-flow effects are directly visible.

The cleanup helper 0xE0726808:
  - calls siriusInstance vtable +0x34;
  - calls service 0x0005742E vtable +0x10 with handle 0xC192F064;
  - if that call returns nonzero, calls the same provider's vtable +0x40 with the handle;
  - calls siriusInstance vtable +0x38.
The names/semantics of these interface slots remain unresolved.

Shared service ID 0x0005742E consumers
-------------------------------------
Three setter sites accept service ID 0x0005742E:
  siriusInstance setter 0xE07140D0 -> field +0x18; aggregate queries vtable +0x54 and +0x58 through this field.
  pe_wait_for_canprint setter 0xE07269B0 -> field +0x10; confirmed subscribe/unsubscribe use in the callback path above.
  pe_iev_job setter 0xE0715950 -> field +0x10; its method-table pointer at ROMFS 0xE0B3584C resolves to 0xE0715951, and the containing component descriptor names pe_iev_job at 0xE0B35798. This establishes accepted injection of the same service ID; direct use of that field by pe_iev_job was not established in this step.
The adjacent ROMFS component name pe_jobdb is a separate record and is not the owner of setter 0xE0715950.

Static ROMFS cross-check
------------------------
The rebuilt ROMFS image contains 19 raw occurrences of 0x000A701E (the siriusInstance dependency ID). It contains no raw 32-bit occurrences of 0x0005742E, 0x0038948E, 0x0096BF7A, or 0x00490F3E. Those IDs are assembled as immediates in setter code rather than exposed as named ROMFS dependency records in this image. Therefore the ROMFS metadata does not supply a provider class/name for these injected interfaces.

What this means
---------------
The token-1 condition belongs to a concrete PE wait-for-canprint state machine. It makes a status query through service 0x0038948E and conditionally subscribes to the wait_for_canprint key through service 0x0005742E. The same 0x0005742E service ID is the interface through which the blocked-state aggregate queries token status at siriusInstance +0x18.
This is a direct architectural connection between the PE wait-for-canprint component and the aggregate's condition service. It is not yet proof that the condition was live on the user's printer during the failed Print-Job, nor proof of an Instant Ink/account cause.

Correction / naming note
------------------------
The third consumer is named pe_iev_job, not pe_jobdb. The adjacent pe_jobdb ROMFS record is separate. Revision 107 carries the corrected component name and explicitly distinguishes setter acceptance from proven field usage.

Still unresolved
----------------
- Concrete provider implementation/class behind service 0x0005742E.
- Concrete provider implementation/class behind service 0x0038948E and the schema/name of its 0xD0-byte result structure, especially offset +0x8C.
- Runtime pointer equality between siriusInstance +0x18 and pe_wait_for_canprint +0x10.
- Whether the method-table path executed on the printer and whether token 1 was active during the failed Print-Job.
- Named semantics of selector values 0x10, 0x1A, 0x87, 0x90 and the vtable methods +0x34, +0x38, +0x40, +0x54, +0x58.
- A direct causal link to alert 66220, Instant Ink/account state, RTP block_print/unblock_print, PE event 0x8D, or the WSCN scanner-status subsystem.

Next highest-value target
-------------------------
Resolve the concrete implementation behind service 0x0038948E and its +0x8C result field, then resolve service 0x0005742E's provider implementation and token-state methods. These are now the narrowest code-level dependencies controlling the PE wait-for-canprint predicate. A runtime capture would be needed to know which provider instance/state was live during the failed job.

Scope
-----
Static firmware analysis only. No printer communication, runtime memory capture, firmware modification, print attempt, or scan attempt was performed.



## Part22_Step21_ConStat_CanPrint_and_InkSub_Error_Policy_Evidence.zip / evidence/STEP21_FINDINGS.txt

HP DeskJet 2855e — Part 22, Step 21 findings
Revision 108 addendum; static firmware analysis only

GOLDEN FINDING
The pe_wait_for_canprint status buffer is a ConStatSystemInfoT object, and the boolean tested at offset +0x8C is the named can_print field. The field is populated from the ConStat object's internal +0x2F8 member. A ConStat error aggregator scans six groups of recorded consumable-error codes and forces can_print false when any stored code is not 0x25. Three explicit Ink Subscription errors map to 0x12, 0x13, and 0x14, so they are blocking inputs to this policy.

1. TYPE AND QUERY RESOLUTION
- pe_wait_for_canprint status query: 0xE07267B8.
- It allocates a 0xD0-byte output buffer, calls its injected service 0x0038948E through vtable slot +0x08, and reads the output word at +0x8C when the provider returns success.
- ROMFS type descriptor at 0xE0C3F968 names C type `constat_system_info_t` at 0xE0C41F00 and C++ type `ConstatSystemInfoT` at 0xE0C41F18.
- Descriptor declares object size 0xCC and 19 fields. The pe_wait 0xD0-byte stack allocation is consistent with this object plus alignment/padding.
- Field descriptor at 0xE0C420B4 names `can_print` and specifies offset 0x8C.
- ConStat getter candidate 0xE0307A38 accepts an output pointer, initializes ConstatSystemInfoT via 0xE03028B0, then populates it through 0xE0308520.
- 0xE0308520 copies ConStat object +0x2F8 into output ConstatSystemInfoT +0x8C.
- A ConStat component method-table segment contains Thumb pointer 0xE0307A39 at slot +0x08 relative to table address point 0xE09AEBA4. This function signature and structure match the pe_wait query. However, the static image does not expose an explicit service-ID-to-runtime-object binding for 0x0038948E. Treat it as a high-confidence provider candidate, not a runtime-observed binding.

2. INTERNAL CAN_PRINT AGGREGATE
- ConStat object's mutable CanPrint source is +0x2F8.
- Six reason groups are rooted at object +0x8F4.
- Each stored reason record contains its numeric error code at record +0x10.
- 0xE0308988 initializes aggregate result to 1, scans the six groups, and changes it to 0 if it finds any record whose +0x10 code is not 0x25. It writes the result to object +0x2F8 if changed.
- 0xE03076C0 records the incoming reason code at record +0x10, triggers recomputation, and immediately clears object +0x2F8 for codes other than 0x25.
- Therefore the observed rule is: no stored reason codes, or all stored codes equal to 0x25 => can_print=1; any stored code other than 0x25 => can_print=0.
- This six-group ConStat reason table is not the 32-entry PE event-condition registry. Their layouts must remain separate.

3. CONSTAT CONSUMABLE-ERROR ENUM MAPPING
The primary `constat_consumable_error_t` metadata maps:
- 0x12 -> CONSTAT_CONSUMABLE_ERROR_INKSUB_NOT_ENROLLED
- 0x13 -> CONSTAT_CONSUMABLE_ERROR_INKSUB_REPLACED_EARLY
- 0x14 -> CONSTAT_CONSUMABLE_ERROR_INKSUB_NO_RTP
- 0x25 -> CONSTAT_CONSUMABLE_ERROR_BAD_MFG_BATCH
A second adjacent metadata table uses the alternate/related label CONSTAT_CONSUMABLE_ERROR_USING_BAD_MFG_BATCH for numeric 0x25. The executable code compares the numeric value only; this report does not treat the labels as separate policy results.
- The three Ink Subscription codes 0x12/0x13/0x14 are all non-0x25 and therefore force can_print false when present in the scanned groups.
- The 0x25 code is the sole non-blocking numeric exception in this six-group scan.

4. PINK SUBSCRIPTION-LEVEL INPUT
- ROMFS identifies DSID 0x00012FB0 as DSID_CONSTAT_INK_SUBSCRIPTION_LEVEL.
- Its declared type is PINK_subscription_status_e with values 1=pink_ss_registered_current_e, 2=pink_ss_registered_issue_e, 3=pink_ss_not_registered_e.
- Function 0xE0302AA6 queries DSID 0x12FB0 via a provider virtual method at +0x10 and writes the returned value to its output argument.
- The exact conversion from the three PINK enum values to ConStat consumable-error values 0x12/0x13/0x14 has not yet been established. This is the next trace target.

5. RELATION TO THE PREVIOUS PE BLOCK PATH
- Step 19 identified pe_wait_for_canprint as the component that registers nonzero PE condition token 1.
- Step 20 recovered its CanPrint status state machine and separate event subscription service `wait_for_canprint` (service 0x5742E).
- Earlier steps identified PE event subtypes 0x8B/0x8C as set/clear transitions for DSID_PRINT_ENGINE_BLOCKED.
- Step 21 now supplies the ConStat-side semantics: the readiness query checks can_print, and specific Ink Subscription consumable errors force it false.
- The exact active reason on the user's printer, and the full runtime handshake from can_print false through token 1 to the PE blocked event, remain unobserved. Do not claim which error was active on the device.

6. IMPLICATIONS AND LIMITS
- This is strong firmware evidence that Ink Subscription eligibility conditions can participate in the printer's CanPrint restriction.
- It is not proof that the user's failed Print-Job was caused by `INKSUB_NOT_ENROLLED`, `INKSUB_REPLACED_EARLY`, or `INKSUB_NO_RTP`; a runtime snapshot of the ConStat reason groups or PINK status is required to distinguish them.
- No device connection, print job, scan job, firmware write, or runtime-memory change was performed.
- The service provider behind 0x0038948E is strongly matched to the ConStat getter by ABI and object type, but the ID-to-object runtime binding remains unresolved.

NEXT TARGET
Trace the ConStat supply/ACF policy path that reads DSID_CONSTAT_INK_SUBSCRIPTION_LEVEL (0x12FB0) and determine which PINK status/violation/trigger combination inserts reason code 0x12, 0x13, or 0x14 into the six ConStat groups. Then establish whether the printer's observed Cartridge or Account Issue maps to one of those conditions.



## Part22_Step23_PINK_ConStat_and_ACF_Path_Separation_Evidence.zip / evidence/STEP23_FINDINGS.txt

PART 22 — STEP 23 FINDINGS
PE/PINK error paths, ConStat reason insertion, and ACF reporting separation

1. PINK mask-selection wrapper recovered
Function 0xE030B478 maps selector r4=1 to mask supplyInksubTooEarly (0x00020000), selector r4=4 to supplyInksubNotEnrolled (0x00010000), and selector r4=3 to supplySharedSelectShorted (0x00200000). It forwards the selected mask through an injected provider interface; the actual receiver target is not yet confirmed. For r6==1 or 2, those flags are selected; r6==3 selects separate auxiliary bits (0x40, 0x80, 0x1000 respectively). This is a mask-selection path; it does not itself call the ConStat reason-insertion routine 0xE03076C0.

2. The earlier dynamic reason candidate is excluded
Function 0xE030BB38 supplies reason 1 when its r8 input is 1; otherwise it uses the result of 0xE0303060. The latter has only two return values: 1 and 4. Therefore this candidate path cannot forward value 0x13. The neighboring insertion helpers examined also use values 0–4 (0xE030BC08), 3 (0xE030BCB0), and 4 (0xE030BD30); the wrapper at 0xE0303E18 uses 2. These observations exclude the previously suspected helper path, not every possible dynamic caller in the image.

3. printhead_failure is a separate report/provider route
Function 0xE071B0D0 saves its incoming reason code in a stack payload field, requests the named action/key “printhead_failure” through 0xE0722C20, then calls an injected provider pointer loaded from 0xC192A068+0x28 (address 0xC192A090) through vtable slot +0. It supplies descriptor 0xE0B372E4. The adjacent ROMFS declaration at 0xE0B372C0 is the string DSID_PE_TRAY2_OPEN_CLOSE_COUNTER. The provider implementation and its downstream receiver are not statically resolved here. There is no direct call from 0xE071B0D0 to 0xE03076C0.

Known callers of 0xE071B0D0: 0xE071E68C passes 0x0D; the Not-Enrolled path at 0xE071F9F6 tail-branches with 0x12; and the No-RTP callback at 0xE071F22A passes 0x14. These values are included in the report payload; they are not evidence that the reporting provider directly inserts those values into the six-group ConStat aggregate.

4. A nearby PE event value 0x13 is not the missing ConStat reason mapping
0xE071E1D0 constructs a separate structured PE-policy message containing 0x13 and sends it via 0xE071E0A0. Its caller/state context is adjacent to the Fpen_change path. It is not proven to be PINK supplyInksubTooEarly or ConStat INKSUB_REPLACED_EARLY. Numeric equality across these event/reason domains must not be treated as a conversion.

5. CDM supply providers are separate resources
The code contains separate CdmSupplyPublicProvider, CdmSupplyPrivateProvider, CdmSupplyAssessmentProvider, and CdmSupplyAlertsProvider modules with distinct registration selectors and resource routes. They are plausible data/reporting paths for supply/account state, but the static paths examined do not directly establish a conversion to ConStat reason 0x13 or a call to 0xE03076C0. Registration selector values are not assumed to be PE nested event IDs.

6. Remaining uncertainty / corrected next target
The PINK TooEarly bit setter is confirmed, but the live provider method it calls and the conversion from that state into ConStat reason 0x13 remain unresolved. A vtable-target/signature check is required before accepting the earlier assignment of slot +0x54 to a particular implementation: 0xE030B478 passes a scalar mask in r2, whereas one static candidate 0xE0308228 treats r2 as a pointer to a structure. Adjacent table entries also create a possible one-word slot-alignment ambiguity. The runtime vptr/service binding must be resolved. No printer interaction, firmware write, or physical print/scan attempt was performed.



## Part22_Step23_PINK_ConStat_and_ACF_Path_Separation_Evidence.zip / qa/QA_SUMMARY.txt

Step 23 QA: 19/20 PASS; 1 FAIL
PASS	source ELF present
PASS	rebuilt .srtext exactly equals ELF section bytes
PASS	DSID string found at VMA 0xE0B372C0
PASS	descriptor data at 0xE0B372E4 available
PASS	PINK flag crosswalk present
PASS	reason helper audit present
PASS	printhead failure callers present
PASS	CDM resource registration map present
PASS	disassembly pink_selector_mask_setter.dis
PASS	disassembly candidate_reason_helper.dis
PASS	disassembly printhead_failure_report.dis
PASS	disassembly not_enrolled_reason_caller.dis
PASS	disassembly no_rtp_reason_caller.dis
FAIL	findings distinguish PINK and ConStat
PASS	findings qualify printhead_failure provider
PASS	DOCX integrity
PASS	PDF page count and size	pages=6
PASS	PDF text extraction
PASS	evidence ZIP integrity	entries=63
PASS	PDF contact sheet exists



## Part22_Step23_PINK_ConStat_and_ACF_Path_Separation_Evidence.zip / qa/pdf_summary.txt

Pages:           6
Page size:       612 x 792 pts (letter)
File size:       149069 bytes



## Part22_Step25_SiriusInstance_Publisher_Callback_Binding_Evidence.zip / evidence/QA_SUMMARY.txt

Part 22 Step 25 — QA summary

- Focused static verifier: 30/30 PASS.
- Source hashes are retained for the original ELF, rebuilt ROMFS objects, and rebuilt .srtext.
- Final DOCX rendered with the canonical document renderer.
- Final PDF: 2 US Letter pages (612 x 792 pt); both pages visually inspected at full rendered resolution.
- No clipping, overlap, broken tables, orphaned headings, or missing glyphs observed.
- PDF is the exact renderer output copied to the report PDF path.
- Previous Step 23 and Step 24 evidence archives are preserved inside the evidence package.
- No printer communication, live status request, print/scan job, firmware write, or physical device action was performed.



## Part22_Step25_SiriusInstance_Publisher_Callback_Binding_Evidence.zip / evidence/STEP25_FINDINGS.txt

PART 22 — STEP 25 FINDINGS
Revision 111 | 20 November 2026

TITLE
PINK publisher and PE CanPrint callback share the same SiriusInstance service binding

GOLDEN FINDING
The publisher object used by PINK notification helpers and the callback registration used by pe_wait_for_canprint are both populated through service ID 0x000A701E, the SiriusInstance service. This resolves the earlier Step 24 ambiguity at the dependency/service-binding level. The raw runtime pointer values returned by the generic service resolver are not present in the static image, so this does not prove bit-for-bit pointer equality; it does prove that both sides request the same logical service key through their component setters.

1. THE PINK OBJECT ROOT IS C1443000
The code at 0xE0309260 materializes r0=0xC1443000 and calls constructor 0xE0308E70. The constructor writes the component's vtable/address-point references at offsets 0x00 through 0x18 and clears dependency fields 0x1C through 0x38. In particular, the secondary interface at C1443000+0x18 receives address point 0xE09AF194.

The ROMFS table at 0xE09AF194 contains Thumb pointer 0xE03091F1 at offset +0x14 (ROMFS address 0xE09AF1A8). This thunk resolves to 0xE03091F0, subtracts 0x18 from its incoming this pointer, and forwards to 0xE0308D90. This binds the dependency setter to the C1443000 root object rather than a guessed neighboring object.

2. THE PINK PUBLISHER FIELD IS SERVICE 0xA701E
Setter 0xE0308D90 compares the injected service identifier in r1 through its encoded sequence of constants. For service ID 0x000A701E, the third equality path reaches 0xE0308E20 and stores the supplied provider pointer r3 at [root + 0x28]. The root is C1443000, so the publisher object is stored at C1443028.

This is independently confirmed by the consumer-side helper 0xE0305708 (and sibling 0xE0305748): each calls 0xE0308F10, which returns C1443000, loads [r0+0x28], obtains that object's vtable, and calls virtual slot +0x18. The first sends event value 0x87; the second sends 0x90.

3. PE WAIT REGISTERS ITS CALLBACK THROUGH THE SAME SERVICE ID
The setter at 0xE07269B0 accepts service ID 0x000A701E and stores provider r3 at pe_wait_for_canprint object offset +0x0C. Its separate service ID 0x0005742E is stored at +0x10.

Registration routine 0xE07268A8 reads the provider at pe_wait+0x0C and calls vtable slot +0x08. It passes context 0xC192F06C, context value 0x2802, token 1, and callback Thumb pointer 0xE0726851 (code 0xE0726850). Unregistration uses the same SiriusInstance provider at vtable +0x0C.

Therefore, the PINK publisher's [C1443028] dependency and the PE waiter's +0x0C dependency both resolve by the same service key 0xA701E. The earlier Step 24 limitation is narrowed: service-level identity is now established; raw runtime object pointer equality is not statically observable.

4. KEEP SERVICE 0x5742E SEPARATE
The pe_wait_for_canprint component also receives service ID 0x0005742E at +0x10. This is a separate provider used for the named wait_for_canprint subscription: subscribe at vtable +0x08 and unsubscribe at +0x10. It is not the service used by the PINK event publisher or the condition callback registration described above.

This distinction matters. The PINK update event arrives through the SiriusInstance service (0xA701E); the waiter then performs its wait_for_canprint subscription lifecycle through its separate 0x5742E collaborator.

5. END-TO-END STATIC CHAIN
PINK per-supply mask update (0xE0308438) -> notification helper 0xE0305708 -> SiriusInstance dependency at C1443000+0x28 (service 0xA701E) -> virtual publish +0x18, event 0x87 -> pe_wait callback registered through its +0x0C SiriusInstance dependency (same service 0xA701E) -> callback 0xE0726850 -> unsubscribe wait_for_canprint via separate service 0x5742E -> re-query ConStat can_print through 0xE07267B8.

The sibling event 0x90 follows the same publish field/method and reaches the same callback branch. The callback handles 0x87 and 0x90 identically: unsubscribe and, if the handle is active, re-query CanPrint.

6. WHAT THIS DOES AND DOES NOT PROVE
CONFIRMED:
- The PINK component root is C1443000.
- Its service setter maps 0xA701E to publisher field +0x28.
- The PINK publisher helper calls that field's vtable +0x18 and emits 0x87 / 0x90.
- pe_wait_for_canprint maps 0xA701E to +0x0C and registers callback 0xE0726850 through vtable +0x08.
- The callback handles 0x87 / 0x90 by re-querying ConStat can_print.
- Service 0x5742E is a separate dependency at +0x10 used for wait_for_canprint topic subscribe/unsubscribe.

NOT PROVEN:
- The runtime service resolver's raw pointer values or whether it returns literally identical pointer values to both components (logical service key identity is established).
- Which PINK subscription flag or ConStat reason was active on the user's printer during the failed job.
- The executable mapping from PINK supplyInksubTooEarly mask 0x00020000 to ConStat reason 0x13.
- That clearing or suppressing a local state would restore printing.

7. REPAIR IMPLICATION
This is now a strong end-to-end notification path that can trigger a CanPrint refresh. It supports seeking a legitimate correction/refresh of the underlying supply or account condition. It does not justify writing internal flags, forcing can_print, or modifying firmware. The aggregate recomputes state from reason groups; the specific active reason and the supported clearing action are still not captured.

8. NEXT TARGET
Trace the resolver implementation for service ID 0xA701E to determine whether it returns a singleton pointer or a component proxy; then trace the ConStat reason writer and its remaining caller path for code 0x13. Do not conflate the distinct 0x5742E wait_for_canprint subscription dependency with the 0xA701E SiriusInstance event publisher/condition service.

SCOPE
Static firmware analysis only. No printer communication, print/scan job, firmware write, or physical device action was performed.



## Part22_Step25_SiriusInstance_Publisher_Callback_Binding_Evidence.zip / QA_SUMMARY.txt

Part 22 Step 25 — QA summary

- Focused static verifier: 30/30 PASS.
- Source hashes are retained for the original ELF, rebuilt ROMFS objects, and rebuilt .srtext.
- Final DOCX rendered with the canonical document renderer.
- Final PDF: 2 US Letter pages (612 x 792 pt); both pages visually inspected at full rendered resolution.
- No clipping, overlap, broken tables, orphaned headings, or missing glyphs observed.
- PDF is the exact renderer output copied to the report PDF path.
- Previous Step 23 and Step 24 evidence archives are preserved inside the evidence package.
- No printer communication, live status request, print/scan job, firmware write, or physical device action was performed.



## Part22_Step26_ConStat_Vtable_and_Reason_Path_Correction_Evidence.zip / evidence/QA_SUMMARY.txt

Part 22, Step 26 — QA summary

- Focused static verifier: 49/49 PASS.
- SHA-256 identity of the original ELF, rebuilt ROMFS objects, and rebuilt .srtext matches the Step 25 baseline.
- Revision 112 DOCX rendered to two page PNGs; both pages inspected at full rendered resolution.
- Revision 112 PDF is two US Letter pages (612 x 792 pt); rendered at 200 dpi; both pages inspected.
- DOCX ZIP structure verified.
- Focused evidence ZIP integrity tested with unzip -t.
- Delivery checksums generated for DOCX, PDF, evidence ZIP, and QA summary.
- Prior Step 25 evidence ZIP preserved inside the Step 26 evidence package.
- No printer communication, status request, IPP/eSCL job, firmware write, reset, or physical device action was performed.

Important analytical limitation:
The runtime vptr returned for dependency service 0x001FF211 is still unresolved. The matched ROMFS table strongly maps +0x54 to the PINK scalar-mask writer and +0x174 to the ConStat system-info copy method, but the runtime pointer value itself was not observed. The earlier E030BB38 -> E03076C0 reason-insertion attribution is withdrawn. The PINK TooEarly mask 0x00020000 -> ConStat reason 0x13 conversion remains unresolved.



## Part22_Step26_ConStat_Vtable_and_Reason_Path_Correction_Evidence.zip / evidence/STEP26_FINDINGS.txt

PART 22 — STEP 26 FINDINGS
Revision 112 | 20 November 2026

TITLE
ConStat vtable mapping and reason-path correction

GOLDEN FINDING
The Step 22 assertion that 0xE030BB38 reaches reason-insertion method 0xE03076C0 through virtual slot +0x174 on the same injected provider used by the PINK mask updater is not supported by the matching vtable layout. The ROMFS address point that coherently maps the +0x54 scalar-mask writer also maps +0x174 to 0xE0307A38, a ConStat system-info copy/status method. Its downstream copy routine places this+0x2F8 into ConstatSystemInfoT.can_print at output +0x8C.

1. SHARED RECEIVER FIELD
0xE0308F10 returns 0xC1443000. The setter at 0xE0308D90 maps service 0x001FF211 to root field +0x20. Both call sites 0xE030B478 and 0xE030BB38 call 0xE0308F10, load [r0+0x20], read the receiver vptr, and invoke a virtual slot on that provider field.

2. MATCHING VTABLE ADDRESS POINT
The candidate ROMFS address point is 0xE09AEA38. Its entry +0x54 is at 0xE09AEA8C and contains Thumb pointer 0xE0308439 (code 0xE0308438). Its entry +0x174 is at 0xE09AEBAC and contains Thumb pointer 0xE0307A39 (code 0xE0307A38).

0xE0308438 receives a supply index in r1 and scalar error mask in r2, resolves the index, loads the error word from this + 0x1AC8 + index*8 + 4, ORs the mask, stores the result, and calls 0xE0305708. This is a strong semantic match for the +0x54 call at 0xE030B478.

3. THE +0x174 METHOD IS A STATUS-COPY PATH
At 0xE030BBCA-0xE030BBDC, the code calls the same provider field through slot +0x174. Under the matching table above, the target is 0xE0307A38. This method uses r1 as an output structure, invokes 0xE0308520, and returns a provider field. It does not consume r2/r3 as a ConStat reason insertion request.

0xE0308520 copies several fields from the internal ConStat object to a caller structure. In particular:
  this + 0x2F8 -> output + 0x8C (ConstatSystemInfoT.can_print)
  this + 0x2FC -> output + 0x90

This establishes a CanPrint/system-info data path, not the claimed dynamic reason insertion.

4. KEEP 0xE03076C0 SEPARATE
0xE03076C0 remains a real routine that manipulates ConStat reason groups at this + 0x8F4 and touches the PINK mask area at this + 0x1AC8. Its function pointer is present at ROMFS address 0xE09AED18. That is not the +0x174 entry of the matching 0xE09AEA38 table. To treat it as a +0x174 entry requires another address point, 0xE09AEBA4; the +0x54 entry for that alternate base is 0xE0308228, whose code passes r2 to 0xE03088E0 as an output-structure pointer. That signature conflicts with the scalar mask supplied by 0xE030B478.

The vptr returned at runtime for service 0x001FF211 is still unresolved. Therefore this is a correction to the earlier asserted same-interface mapping. It is not proof that no other interface can call 0xE03076C0.

5. CONSEQUENCE FOR TOOEARLY -> CONSTAT 0x13
PINK supplyInksubTooEarly remains mask 0x00020000. ConStat INKSUB_REPLACED_EARLY remains reason code 0x13. The old E030BB38 candidate no longer proves that the derived 1-or-4 value reaches the reason-insertion method. The executable conversion is still unresolved.

6. NEXT TARGET
Resolve service 0x001FF211 through the generic component registry and establish its actual runtime vptr. Then find genuine callers of 0xE03076C0 (or another verified reason-insertion entry) and follow any path carrying mask 0x00020000 or reason 0x13.

SCOPE
Static firmware analysis only. No printer communication, runtime status request, IPP/eSCL job, firmware write, reset, or physical action occurred.



## Part22_Step27_Service_F8AE47_ConStat_Reason_Ingress_Evidence.zip / evidence/STEP27_FINDINGS.txt

Part 22, Step 27 — Service 0x00F8AE47 and the ConStat reason-ingress callback family

Confirmed service mapping
- Setter: 0xE0308D90.
- Service key: 0x00F8AE47.
- Stored field: C1443000 + 0x30 (C1443030).
- Arithmetic: 0x00F8AE47 - 0x00223EE5 = 0x00D66F62; - 0x0044059E = 0x009269C4; - 0x0078A8D1 = 0x0019C0F3; - 0x00125DAB = 0x00076348; terminal comparison is 0x00076348; equal branch stores r3 at +0x30.

ConStat descriptor crosswalk
- Special ROMFS component name string: 0xE09A8FA8, "constat".
- Method table pointer at 0xE09A8FB0 -> 0xE09A8FB4.
- Its nearby service arrays decode as Array A: six records beginning 0xE09A8E40; Array B: nine records beginning 0xE09A8ED0.
- Array B includes service 0x00F8AE47 at record 0xE09A8F48. The component's Array A list does not include 0x00F8AE47.
- In the independent Part 8 crosswalk across 59 standard headers, 0x00F8AE47 occurs in 32 Array B dependency records, across 32 components, and zero Array A records. Therefore its provider is not identified among the 59 standard advertised-service records; it may be supplied by a global/system or alternate registration path, but that is not proven.

Reason-ingress callback family
- ROMFS pair at descriptor pointer slot 0xE09AE540 / method pointer slot 0xE09AE544: descriptor 0xE09AE674, callback 0xE030FB41 -> code 0xE030FB40.
- 0xE030FB40 queries the injected provider at C1443030 through vtable +0x24 with a 20-byte local record (r1=sp+0x18, r2=0x14), parses the record via 0xE03053F8 to obtain a group identifier, then invokes provider vtable +0x18 to obtain a candidate reason value. It resolves the selected ConStat object through 0xE030FEB8 and calls selected-object slot +0x2C0. In the selected object's vtable, +0x2C0 is 0xE03076B0, which forwards to +0x2C4 / 0xE03076C0, the actual reason inserter.
- Adjacent ROMFS pair 0xE09AE54C/0xE09AE550 maps to descriptor 0xE09AE698 and callback 0xE030FC18. It queries four scalar values from provider +0x18 and calls selected-object +0x2C8 (0xE03077F0), which stores a 16-byte record in the object's auxiliary table.
- Adjacent pair 0xE09AE558/0xE09AE55C maps to descriptor 0xE09AE6B4 and callback 0xE030FD18. It queries three scalar values and calls selected-object +0x2CC (0xE0307828), which stores them and invokes a further provider operation.
- These are adjacent table entries and share dependency 0xF8AE47. The descriptor bytes are retained as raw data; their semantic names are not decoded.

Limits / correction
- The concrete implementation behind service 0x00F8AE47 is still unresolved. The same service is widely requested but no provider appears in the 59 standard Array A records inspected.
- The call chain proves how 0xF8AE47's returned values can reach ConStat reason insertion; it does not prove that the value returned for any particular PINK error is 0x13.
- The PINK TooEarly mask 0x00020000 -> ConStat INKSUB_REPLACED_EARLY reason 0x13 conversion remains unproven.
- No runtime call execution, printer state capture, or device-side pointer identity has been observed. These are static paths only.



## Part22_Step27_Service_F8AE47_ConStat_Reason_Ingress_Evidence.zip / evidence/crosswalks/service_F8AE47_standard_component_summary.txt

total_records: 32
array_A_records: 0
array_B_records: 32
unique_components: 32



## Part22_Step27_Service_F8AE47_ConStat_Reason_Ingress_Evidence.zip / QA_SUMMARY.txt

Step 27 QA summary

Focused verifier: 28/28 PASS.
DOCX: 3 US Letter pages; rendered with the canonical DOCX renderer; all 3 pages visually inspected.
PDF: 3 US Letter pages; independently rendered at 200 dpi; all 3 pages visually inspected.
DOCX ZIP integrity: passed.
PDF structure: 3 pages, 612 x 792 pt (US Letter), unencrypted.
Evidence ZIP: ZIP CRC/integrity check passed.
Source inputs: ELF, rebuilt .srtext, and rebuilt ROMFS SHA-256 matched the preserved Step 26 baseline.
Crosswalk verification: service 0x00F8AE47 maps to C1443000+0x30; ConStat Array B includes the key; 32 Array B dependency records and zero Array A provider records were found across the 59 standard component headers.
Limit: concrete service provider and PINK 0x00020000 -> ConStat reason 0x13 conversion remain unproven.
No printer communication, physical print/scan, or firmware modification was performed.



## Part22_Step28_PINK_TooEarly_Status_and_Acknowledgement_Evidence.zip / evidence/STEP28_FINDINGS.txt

PART 22, STEP 28 — PINK TOOEARLY MASK: STATUS/ACKNOWLEDGEMENT PATH
Date: 20 November 2026
Scope: Static analysis only. No device communication, printing, scanning, or firmware writes.

1. PRIMARY FINDING
The PINK supply-error mask bit `supplyInksubTooEarly = 0x00020000` is written by a `constat_helper` update routine and read by a separate `constat_helper` status-decoding routine. The reader extracts bit 17 (`UBFX #0x11, #1`) and stores it into a caller-provided status byte. This proves an executable use of the exact TooEarly bit, beyond its enum declaration.

2. PINK MASK UPDATE
Function `0xE030B478` obtains a per-supply index from the supplied supply key, constructs a mask according to selector/state arguments, then invokes the injected provider at `C1443000 + 0x20` through virtual slot `+0x54`.
For selector `r4 = 1`:
- state `r6 = 1` sets mask bits `0x00020000` and `0x00000040`;
- state `r6 = 2` sets `0x00020000` only;
- state `r6 = 3` sets `0x00000040` only.
Thus the exact bit `0x00020000` is produced by an executable state transition, not merely declared in metadata.

3. MASK STATUS READ
Function `0xE030B2A8` processes event selectors `0x6C` and `0x6D`:
- `0x6C` queries DSID `0x00012FC2`, whose ROMFS label is `DSID_CONSTAT_USER_ACK_BITS_K`;
- `0x6D` queries DSID `0x00012FC6`, whose ROMFS label is `DSID_CONSTAT_USER_ACK_BITS_CMY`.
It then queries the PINK mask provider at `C1443000 + 0x20` through virtual slot `+0x50`, uses the returned mask in `r5`, and includes the exact instruction `UBFX r0, r5, #0x11, #1` followed by a byte store to the caller's output pointer. For `r8 = 1`, the `r4 = 2` branch leaves this bit-17 result in the output byte; the `r4 = 1` branch is subsequently overwritten by a separate bit-6 result.
This is a mask-to-status/acknowledgement calculation. The routine does not call the ConStat reason writer and does not itself write `DSID_PRINT_ENGINE_BLOCKED`.

4. SERVICE KEYS USED BY THE HELPER ROOT
The setter `0xE0308D90` maps these service IDs to the corresponding fields of the object returned by `0xE0308F10` (`C1443000`):
- `0x001FF211` -> `C1443000 + 0x20` (PINK supply-mask interface used by the update/read routines above)
- `0x00DEED54` -> `C1443000 + 0x1C` (DSID access interface used for the user-ack DSIDs)
- `0x00F8AE47` -> `C1443000 + 0x30` (notification/reason-ingress dependency examined in Step 27)
The IDs are reconstructed from the setter's complete cumulative subtract-and-compare path, not guessed from nearby strings.

5. CONSTAT REASON WRITER IS A SEPARATE OPERATION
`0xE03076C0` is the selected ConStat reason-group writer. It accesses a per-supply 8-byte record layout at `this + 0x1AC8 + index*8`, using the same supply-index helper `0xE0307890` as the PINK mask functions. It also updates reason groups beginning at `this + 0x8F4` (record stride `0x40`) and sets `can_print` at `this + 0x2F8` to zero for any inserted reason other than `0x25`.
Its special mask branches compare decimal reason values 11, 12, and 13 and update bits `0x01000000`, `0x02000000`, and `0x00800000` respectively. These decimal values are not the Ink Subscription reason identifiers `0x12`, `0x13`, `0x14` (decimal 18, 19, 20), and the associated masks are not the PINK flags `0x00010000`, `0x00020000`, `0x00040000`.
The shared object-relative record layout is a meaningful structural connection, but runtime identity of the `this` pointers used by the PINK and reason-writer interfaces is not established. No direct conversion from the TooEarly mask to reason `0x13` has been demonstrated.

6. CORRECTION TO THE SERVICE 0xF8AE47 HYPOTHESIS
The special ROMFS descriptor at `0xE09B3AC0` associates service key `0x00F8AE47` with the label `def_not` and a set of method pointers. Its candidate `+0x18` thunk (`0xE031E790`) reaches `0xE031E558`, which registers a notification key and callback pointer in a global table and returns a lock-release status (0 on success, -1 on release failure). The ConStat callback's argument preparation does not match a clean direct reason-value getter contract. Therefore the `def_not` descriptor is not accepted as the confirmed implementation of the `C1443000 + 0x30` provider. The provider identity remains unresolved; Step 27's description of `+0x18` as a confirmed reason-value source is withdrawn.

7. SUBSCRIPTION-LEVEL DSID IS A DISTINCT INPUT
The firmware has a separate getter `0xE0302A98` that queries `DSID_CONSTAT_INK_SUBSCRIPTION_LEVEL` (`0x00012FB0`) through the DSID provider. The examined calls and metadata do not establish a path from that level value or from the TooEarly status byte to ConStat reason `0x13`.

8. CONCLUSION / OPEN EDGE
Confirmed: the PINK TooEarly bit is set by a state-dependent updater and read by a status/acknowledgement decoder; the exact user-ack DSIDs are identified; the ConStat reason writer independently drives `can_print`.
Not confirmed: that the TooEarly bit or its acknowledgement output becomes `INKSUB_REPLACED_EARLY` reason `0x13`, or that the printer had this bit active during the failed Print-Job.
Next target: trace the caller-provided status byte from `0xE030B2A8` into its destination and locate the runtime provider implementation behind `C1443000 + 0x30`; in parallel, identify a direct or dynamic caller that inserts decimal reason 19 (`0x13`) based on the PINK error state.



## Part22_Step28_PINK_TooEarly_Status_and_Acknowledgement_Evidence.zip / qa/QA_SUMMARY.txt

Step 28 QA summary
DOCX rendered to 3 US Letter pages; all 3 pages visually inspected.
PDF rendered from DOCX; page count and page geometry checked by verifier.
Focused firmware/evidence verifier: 35/35 PASS.
Evidence SHA-256 manifest regenerated from final evidence files (manifest excludes itself).
Evidence ZIP rebuilt and archive integrity plus embedded evidence hashes checked.
No printer communication, printing, scanning, or firmware modification occurred.



## Part22_Step32_Pen_TooEarly_Write_Path_Audit_Evidence.zip / evidence/QA_SUMMARY.txt

STEP 32 QA SUMMARY

Report: Revision 118 / Part 22 Step 32
DOCX: 5 US Letter pages; rendered to five PNGs and all inspected at 100%.
PDF: 5 US Letter pages; independently rendered with PDFium and all inspected at 150 DPI.
Focused structural verification: 39 checks, 39 passed, 0 failed.
Source provenance: Five source artifact SHA-256 values recorded in SOURCE_INPUTS.txt.
Baseline packages: Step 31 evidence ZIP and Part 1 firmware evidence ZIP both passed nested integrity tests.
Scope: Static analysis only; no printer operation, firmware modification, state write, or event injection.



## Part22_Step32_Pen_TooEarly_Write_Path_Audit_Evidence.zip / evidence/STEP32_FINDINGS.txt

HP DeskJet 2855e - Part 22, Step 32 (Revision 118)
Pen TooEarly mask write-path and reset audit

EXECUTIVE RESULT
The Pen mask service reader combines main state-bank field 0x1F and secondary property field 0x32. The Pen service writer at 0xE07399E8 and registered notification router at 0xE0737C08 are additive OR paths. Neither can remove an already stored TooEarly bit by sending a request that omits it. A separate conditional reconciliation path can clear the main field and then normalize the secondary mirror.

CONFIRMED ADDITIVE PATHS
1. 0xE07399E8 validates the supply key, reads main[bank0,0x1F] and secondary[0x32], ORs both with the requested mask, then writes the merged value back to both stores.
2. 0xE0737C08 has independent supply-key 0 and 1 branches. Each checks 0xE0728658, reads main[bank0,0x1F], ORs in the incoming payload, and writes via 0xE07372B0. A Thumb callback pointer to 0xE0737C09 is found in the firmware, ELF, and rebuilt ROMFS images. The associated descriptor IDs remain semantically unlabeled.

CONDITIONAL CLEAR / MIRROR RECONCILIATION
1. 0xE07281A0 compares two per-supply snapshot structures using 0xE073E1C0, which returns classes 0..3.
2. The cleanup branch at 0xE0728264 occurs when both comparison classifications are below 2. Under that condition, the routine copies the 77-field bank-0 record to bank 1 and later writes zero to main bank-0 field 0x1F via 0xE07372B0 at 0xE072831C.
3. 0xE0729298 loops over supply keys. If 0xE0728658 returns nonzero, it copies main field 0x1F into secondary field 0x32. If the validator returns zero, it zeros secondary fields 0x32..0x36. Because the main field was set to zero by the cleanup branch, either route can leave the secondary reader input zero too.
4. The validator is a compound eligibility check involving per-key state, secondary field 0x15 decode, context/ownership-shaped helper calls, another per-key byte, and opaque property 0x095F / selector 0x4D. Their business labels are not established.

ADDITIONAL WRITE-PATH FINDINGS
- 0xE0737650 contains bulk zeroing writes including main 0x1F and secondary 0x32..0x36, but the scanned firmware, ELF, dump, and ROMFS inputs contain no direct branch/call or absolute function-pointer reference to 0xE0737650/0xE0737651. Runtime reachability is unproven; do not count it as an established reset path.
- Registered router callback 0xE0737C08 only ORs incoming mask bits into main field 0x1F, so it can reassert the bit but cannot clear it.

STEP 31 CALLBACK CORRECTION
The syntactic call at 0xE0748F26 to 0xE07271D0 is behind BEQ at 0xE0748B60. The guard 0xE073C150 returns 1 in this firmware image: 0xE073C178 returns 1; wrappers 0xE073C0E8 and 0xE073C0D8 set r0=0 before calling bit-test helper 0xE073C0A8, therefore both return 0; 0xE073C150 consequently returns 1. The BEQ is not taken, so 0xE0748F26 is not reachable through registered callback 0xE0748B08. The earlier claim that this callback was a live trigger is withdrawn.

OTHER PARENT CALLS
Direct calls to parent 0xE07271D0 include 0xE073D250 (mode 0), 0xE073D4B2 (mode 2), 0xE073D988 (mode 0), 0xE073DBC8 (mode 0), and 0xE073DC4E (mode 0). 0xE0729656 has a tail branch to it after preceding checks. The unreachable callback callsite is excluded from live parent callers.

RECOVERY INTERPRETATION
There is a real internal state-reconciliation path that can clear the two fields consumed by the Pen TooEarly mask reader, but its eligibility depends on internal snapshot classes and per-key guards. No supported user command, UI action, or safe manual invocation was found. The additive writer/router may reassert the bit. No proof connects this path to the previously observed EWS “Cartridge or Account Issue” or ConStat reason 0x13 at runtime. This analysis does not provide or recommend a bypass.

NEXT TARGET
Trace the producers of both compared Pen snapshots; identify metadata for secondary property field 0x15, per-key state bytes, and property 0x095F / selector 0x4D; establish which normal Pen lifecycle transition can make both snapshot classes less than 2. Also decode the descriptor IDs associated with the registered 0xE0737C08 router before assigning them business labels.

SCOPE
Static firmware analysis only. No printer communication, print/scan job, firmware write/flash, DSID write, event injection, account change, or access-control bypass was performed.



## Part22_Step33_Pen_Identity_and_Validator_Audit_Evidence.zip / evidence/STEP33_FINDINGS.txt

HP DeskJet 2855e Firmware Investigation
Part 22 - Step 33 / Revision 119
Pen identity snapshots, classifier, and TooEarly reconciliation gates

EXECUTIVE RESULT
Step 33 identifies the data carried by the Pen snapshots used by the conditional TooEarly-state reconciliation. The snapshots are supply-identity records: they contain the physical slot's Pen Type, Pen ID Version, and 16 Pen ID bit-block DSIDs. The reconciliation validator also reads per-slot state and context/configuration gates. This makes the conditional reset path an identity/state-reconciliation mechanism, not a direct subscription-entitlement unlock.

1. PEN IDENTITY SNAPSHOT CROSSWALK
- E07372D0 builds a 0x94-byte snapshot for a Pen slot. It obtains fields 0x16 through 0x26 through E0737140.
- E0737140 uses the DSID pointer table at 0xE0B3EC40 with index slot_key + (2 * snapshot_field).
- E07373C0 writes the 0x16..0x26 fields through E0737168 to the secondary property store.
- The field-0x15 Pen Type DSID is read by E07285A8 using E0737140.

Field 0x15 (Pen Type):
  slot 0 / left-K: 0x000100E1, DSID_PEN_CHUTE_DS_LEFT_PEN_TYPE
  slot 1 / right-CMY: 0x000100E2, DSID_PEN_CHUTE_DS_RIGHT_PEN_TYPE

Field 0x16 is Pen ID Version:
  left-K 0x00011D41; right-CMY 0x00011D46.
Fields 0x17..0x26 are Pen ID Bits 0..15:
  - bits 0..3: fields 0x17..0x1A; left 0x00011D42..0x00011D45, right 0x00011D47..0x00011D4A
  - bits 4..7: fields 0x1B..0x1E; left 0x000129C2..0x000129C5, right 0x000129C6..0x000129C9
  - bits 8..15: fields 0x1F..0x26; left 0x00012E8B..0x00012E92, right 0x00012E93..0x00012E9A
All 36 left/right DSID entries were extracted from the table and cross-checked against ROMFS metadata labels. The complete mapping is in crosswalks/pen_identity_dsid_crosswalk.csv.

IMPORTANT FIELD-NUMBER COLLISION
The Pen identity snapshot's field 0x1F is Pen ID Bits 8. This is not the same storage as the main Pen mask bank's field 0x1F used by the TooEarly reader. The latter is a field in a different 77-field per-supply main-bank record. Likewise, secondary property field 0x32 used by the mask reader is a separate storage context from snapshot/classifier output field 0x32. Numeric equality alone does not imply shared meaning.

2. PEN TYPE NORMALIZATION (CORRECTED)
E07285A8 reads the slot's raw Pen Type DSID. The adjacent normalizer E07285B0 maps:
  raw value 0 -> normalized 1
  raw value 1 -> normalized 0
  raw value >= 2 -> normalized 5
These are exact branch outcomes. The firmware metadata reviewed here does not supply human-readable meanings for normalized values 0, 1, and 5. This corrects the earlier Step 31 interpretation, which incorrectly placed raw value 2 in the normalized-0 branch.

3. 45-ROW PEN ID CLASSIFIER
- E0734548 obtains property 0x24 and combines it with the Pen ID Version stored at snapshot offset +0x04: composite_key = property_0x24 OR (Pen_ID_Version << 28).
- E0732F28 compares that key against 45 entries at 0xE0B3E244, with 0x18-byte rows and a zero-key terminator after the 45 valid entries.
- The table has groups for version nibbles 5, 6, 7, 8, and 9.
- Its route-selector/output-field distribution is:
    version 5: 10 rows, selector 1 -> snapshot field 0x16
    version 6: 8 rows, selector 0 -> field 0x1B; 1 row (key 0x6000000F), selector 1 -> field 0x32
    version 7: 7 rows, selector 0 -> field 0x1D; 7 rows, selector 1 -> field 0x1F
    version 8: 4 rows, selector 0 -> field 0x24; 4 rows, selector 1 -> field 0x26
    version 9: 2 rows, selector 0 -> field 0x2B; 2 rows, selector 1 -> field 0x2C
- All 45 rows have zero in both auxiliary flag bytes, zero optional property ID, and zero reserved word.
The classifier's numeric route selectors and target fields have not been assigned business meanings beyond their exact decoded operations. The complete 45-row table is in crosswalks/pen_identity_classifier_table.csv.

4. VALIDATOR INPUTS AND PROPERTY-GATE CORRECTION
E0728658 is a compound per-slot guard. The observed inputs include:
- per-slot dword at C192F54C + slot (base C192F4A8 + 0xA4)
- per-slot status byte at C192F554 + slot (base + 0xAC)
- Pen Type normalized by E07285B0
- another per-slot byte at C192F4F6 + slot (base + 0x4E)
- current-context/ownership guards involving C192F0AC or C193790C, E0700460, and E0752410
- a per-slot status-byte lookup through E07296C8
- property-presence check E0743380 for property provider/key 0x095F, selector 0x4D

The property helpers must not be conflated:
- E0743380 calls E072D6B8(0x095F, 0x4D) and returns 1 if the property lookup returns null, otherwise 0. E0728658 calls this existence predicate as one branch of its compound guard.
- Adjacent routine E07433A0 is a richer object helper. When the property exists, it checks property 0x9 on the returned object; on one branch it extracts bits 12..21 from the dword at object offset +0x0C. If that branch is not taken, it branches to fallback routine E0743508. This 10-bit extraction is not the direct operation performed by E0728658's call to E0743380.
- E073AA00 and E0726C18 compare stored global context identifiers to the current context from E0700460 and consult E0752410. The executable evidence establishes context/ownership-shaped gates, not their human-facing business meaning.

E0732D98 wraps the base validator and further gates the result using E0735728 and E0746020. It returns 0 or 0x17; no metadata reviewed here labels those values as subscription enrollment or entitlement states. Therefore validator true/false must not be translated into “subscription fixed”, “cartridge rejected”, or “account locked”.

5. SNAPSHOT COMPARATOR AND ITS ROLE IN RECONCILIATION
- E073E1A0 calls E073E1C0 and returns boolean 1 only when the internal comparison class is exactly 3.
- E073E1C0 first compares a 0x8C-byte block beginning at snapshot +0x08. If identical it returns class 3. If not, it evaluates other per-snapshot helper values, property 0x34 presence/content, and a further set of per-entry properties; observed return classes are 0..3.
- The E07281A0 cleanup path uses these classes with asymmetric first/second-snapshot conditions; the ordinary bank cleanup branch is taken only for the required below-2 comparison results. Do not reduce this to a plain “identity matches” boolean.
- Under that branch, E07281A0 copies/reconciles the main 77-field record and writes zero to main-bank field 0x1F. E0729298 then synchronizes the secondary mirror: validator true copies the now-cleared main field 0x1F into secondary field 0x32; validator false zeros secondary fields 0x32..0x36.
- The Pen mask reader E07397F0 ORs main-bank field 0x1F with secondary field 0x32 (plus a separately gated 0x800 flag). Thus the reconciliation sequence can remove the TooEarly bit from both mask-reader inputs when its gates pass.

6. RECOVERY INTERPRETATION
The source of the two compared snapshots is now identified as Pen Type and Pen ID identity data plus additional per-snapshot properties. That supports the interpretation that the conditional reset is tied to Pen identity/state reconciliation. It does not establish which cartridge insertion, replacement, identification, or account event causes both comparison classes to fall below 2. No supported external command, UI action, or user-invokable service endpoint to force this reconciliation was found. The additive writer/router can later reassert the flag if the upstream source condition persists.

The current best route is to trace the production producers of the Pen Type/ID DSIDs and the property-0x24 input, then connect them to the update callbacks that call E07271D0. Do not write DSIDs, mutate fields, inject events, invoke internal methods, or flash firmware as a workaround.

SCOPE AND SAFETY
Static firmware analysis only. No printer communication, print/scan job, firmware write or flash, DSID write, event injection, account change, or access-control bypass was performed. Runtime printer state and the relation between the reported EWS “Cartridge or Account Issue” and this exact TooEarly bit remain unproven.

SOURCE INPUTS
- tassel_LBI_verified.bin SHA-256: 2ae39ef1771c5f9a23c1bf0d6bd606d360fbe76fbbb8210226cfb42df6d4925e
- dump.bin SHA-256: b791436cf9152785fb5d3f6954aa5949d4ae7c7458af0e2031b9a41f5534c496
- hp_lbi_sections.elf SHA-256: 25f96849938f55976e7f63cd9950d27c6d2a20cc3b9938fdaf9c6ac286f5a8f7
- srtext_full_thumb.dis SHA-256: 7bd2f496ed6a200f38112fb8e75df5059e7a3a2accc925443daa26126bf00301
- romfs_objs_rebuilt.bin SHA-256: 227cf6f8a8e7551dbd5dce710eef7e0866fb3212db8e717f334125619ae90fd3
- Part 1 RTP provider evidence ZIP SHA-256: 511fc8ac874b67a6caf0a52888e0a7c6ea1ab14f43c0c45902fd3fb0c55b21ee



## Part22_Step33_Pen_Identity_and_Validator_Audit_Evidence.zip / evidence/source/STEP31_FINDINGS.txt

HP DeskJet 2855e Firmware Investigation
Part 22 - Step 31 / Revision 117
Pen service 0x1FF211: TooEarly mask storage and conditional reconciliation

EXECUTIVE RESULT
The provider behind ConStat's PINK mask service 0x001FF211 is the Pen component's second interface. Its reader and writer ABI match the ConStat callsites. The writer is additive (existing-main OR existing-secondary OR requested mask), so omitting bit 0x00020000 from a request cannot clear an already stored TooEarly bit through that method.

A separate Pen reconciliation path can rewrite and zero the two backing locations that the reader ORs together. This is a genuine firmware state-maintenance path, not a standalone user command:
- E07281A0 performs a conditional state-bank reconciliation. It compares two Pen state/snapshot structures through E073E1C0. The comparison returns a classification, not a simple equality boolean. A first comparison classification >= 2 takes an early-return path; otherwise the routine enters the bank synchronization / selected-field cleanup path, which explicitly writes zero to main-bank field 0x1F among other fields.
- E0729298 then reconciles per-supply secondary properties. For each of two supply keys, it calls E0728658. If the validator returns nonzero, the routine copies main bank-0 field 0x1F to secondary field 0x32. If the validator returns zero, it explicitly zeroes secondary fields 0x32 through 0x36.
- The reader E07397F0 returns the OR of main-bank field 0x1F and secondary field 0x32 (plus an independently gated 0x800 flag). Thus, when the main field has been reset and the secondary reconciliation copies that zero or explicitly clears field 0x32, the TooEarly bit is absent from both stored inputs read by this service.

IMPORTANT QUALIFICATION
Do not simplify E073E1C0 to a plain "equal/not equal" predicate. It returns a small classification (0..3). The E07281A0 caller tests >=2 and has asymmetric handling for the first versus second comparison. The report therefore calls this a conditional snapshot/bank reconciliation branch, not an unconditional reset every time E07281A0 runs.

PROVIDER AND STORAGE CROSSWALK
- Component: pen.
- Advertised service: 0x001FF211 (Pen service-array entry A[1]).
- Pen constructor: E0746A08 installs five interface address points on the Pen object; the second address point is E0B4CAAC.
- Second interface +0x50 -> thunk E0747069 -> reader E07397F0.
- Second interface +0x54 -> thunk E0747061 -> writer E07399E8.
- Reader main input: E0737248(key, bank=0, field=0x1F).
- Reader secondary input: E0737140(key, field=0x32).
- Writer reads both inputs, ORs them with the requested mask, and writes the merged mask to the main and secondary stores. It is monotonic/additive for these bits; this method itself does not clear.
- The main store is a key x bank x 77-field table; the secondary store is a key x secondary-field table. The same exact read/write wrappers are used by the reset/reconciliation routines.

RECONCILIATION DETAILS
1. E07281A0 (one caller within E07271D0 at E0727954) compares current and reference Pen state data. E073E1C0 compares multiple fields/substructures and returns a classification. The routine has an early-return on a >=2 class for its first compare; other paths proceed through bank synchronization and cleanup.
2. In the cleanup path E07281A0 copies the 77-field main record between banks, then explicitly sets selected fields in main bank 0 to zero, including field 0x1F. The reset uses E07372B0 directly, not the additive mask API.
3. E0729298 (called from E07271D0 at E0727F0A) calls E0728658 for keys 0 and 1. True: secondary field 0x32 is replaced with main bank-0 field 0x1F. False: secondary fields 0x32..0x36 are written as zero.
4. This means a legitimate lifecycle reconciliation can remove the TooEarly bit from the two data sources that the Pen service reader ORs. It does not prove the underlying subscription/account issue has been resolved; an upstream update may recreate the bit if the source condition remains.

VALIDATOR: WHAT IS AND IS NOT KNOWN
E0728658 is a compound per-supply guard, not a simple subscription-enrolled predicate. It reads per-key state, uses the property-field-0x15 decoder E07285A8, checks several per-key flags, and invokes additional context/configuration helpers. In particular:
- E07290E0 checks a current manager/context condition.
- E0726C18 and E073AA00 compare stored manager/context pointers against the current context helper E0700460 and consult E0752410. These are execution-context/ownership guards, not evidence of an Ink Subscription entitlement state.
- E0743380 evaluates a separate property/configuration query (key 0x095F, selector 0x4D) via E072D6B8. The business label for this pair is unresolved.
- E07296C8 reads a separate per-supply byte/record field. Its business meaning is unresolved.
- E07285A8 maps raw secondary field 0x15 values 0 or 1 to 1, value 2 to 0, and values >=3 to 5. The meaning of these numeric states is not identified by the executable evidence reviewed here.

Therefore, this work does not establish that validator=true means "subscription fixed", nor that validator=false means "cartridge rejected". It establishes only the exact data/control dependencies.

CALLER / LIFECYCLE CONTEXT
E07271D0 is a broad Pen state-update/reconciliation routine. Static direct callers include E073D250, E073D4B2, E073DBC8, E073DC4E and E0748F26. At least one mode-0 path follows an initialization sequence; another caller passes mode 2 after a status/update sequence. The reset helpers are called within this broader state update and are not exported as a standalone unlock endpoint in the examined code.

IMPLICATION FOR PRINT RESTORATION
This is the first confirmed route that can clear both stored copies underlying the TooEarly PINK mask. It is a conditional, internal state-reconciliation route. No supported user-invokable command to trigger it was identified. Do not manually invoke E07281A0/E0729298, write fields directly, inject events, or call rtp_manager.unblock_print. Those would be internal firmware manipulations, not a verified supported recovery procedure.

The RTP method rtp_manager.unblock_print remains registered in an internal method table, but its transport/access path and production provider implementation are not fully resolved. It is not evidence of an available or safe public unlock command. The separate PE event aggregate/DSID machinery remains distinct from the Pen mask and ConStat reason pipeline.

UNRESOLVED
- What exact real-world state transition causes E07271D0's comparison path to permit bank cleanup?
- What are the semantic labels for Pen field 0x15, the per-key state bytes, and property pair (0x095F, 0x4D)?
- Does the currently observed printer state satisfy the internal reconciliation preconditions? Static firmware analysis alone cannot answer runtime state.
- Does the printer's EWS "Cartridge or Account Issue" correspond to this exact TooEarly bit or to another PINK/ConStat reason? That runtime mapping is not yet proved.

SCOPE / SAFETY
Static firmware analysis only. No printer communication, physical print/scan job, event injection, state write, firmware modification, flashing, account change, or bypass was performed.

SOURCE INPUTS
- tassel_LBI_verified.bin SHA-256: 2ae39ef1771c5f9a23c1bf0d6bd606d360fbe76fbbb8210226cfb42df6d4925e
- dump.bin SHA-256: b791436cf9152785fb5d3f6954aa5949d4ae7c7458af0e2031b9a41f5534c496
- hp_lbi_sections.elf SHA-256: 25f96849938f55976e7f63cd9950d27c6d2a20cc3b9938fdaf9c6ac286f5a8f7
- srtext_full_thumb.dis SHA-256: 7bd2f496ed6a200f38112fb8e75df5059e7a3a2accc925443daa26126bf00301
- romfs_objs_rebuilt.bin SHA-256: 227cf6f8a8e7551dbd5dce710eef7e0866fb3212db8e717f334125619ae90fd3

The original full firmware/source evidence remains preserved in the earlier Part 1 evidence package. The focused Step 31 archive contains disassembly excerpts and hashes to tie this addendum back to those inputs.



## Part22_Step8_CROM_Sirius_Service_Descriptor_Trace_Evidence.zip / evidence/README_PART22_STEP8.md

# Part 22 Step 8 - branch-aware CROM `sirius` and service-string trace

## Scope

Static-only analysis of the FHX `.cromsrtext` section around its three lowercase `sirius` byte strings and relevant nearby `Provider`, `Service`, `service`, and `register` fragments. This step does not access the printer, submit network requests, change configuration, or modify firmware.

## Provenance and section mapping

The rebuilt FHX secure payload has size 12,888,320 bytes (`0xC4A900`) and SHA-256:

`aaeb7197100755740b0bbf759526b851b5b26708ba2328bdf9db2710aea80858`

The 125-entry FHX directory maps `.cromsrtext` to VMA `0xE1A76480`, size `0x529E00` (5,414,400 bytes), payload offset `0x71E640`. The section ends at payload offset `0xC48440`. Its SHA-256 is:

`203a68ecf7d8f3c3b4398b75ada83a31b48d1e51c0772cb569279a6a9402d97f`

`CROM_SR_TEXT_SECTION.bin` is the exact extracted section. `extract_crom_section.py` reproduces it from the full rebuilt FHX payload. `FHX_DIRECTORY_125.csv` and `FHX_RELEVANT_DESCRIPTORS.txt` preserve the descriptor evidence.

The section has 256 distinct byte values, 154,254 zero bytes, 176,315 `0xFF` bytes, and Shannon entropy 7.5660934245 bits/byte, consistent with the previously reported inventory.

## Main findings

The three `sirius` hits are at section offsets `0x724E5`, `0x432036`, and `0x445016` (VMAs `0xE1AE8965`, `0xE1EA84B6`, and `0xE1EBB496`). Each lies inside a directly decoded 16-bit Thumb unconditional-branch skipped interval. The branch instruction bytes, target arithmetic and containment checks are retained in `BRANCH_BOUNDARY_INVENTORY.csv` and `LLVM_BRANCH_VERIFICATION.txt`.

The local data contexts differ:

1. A build-path fragment contains `autobuild/sirius_hub_release`, a `tassel_box_pp1` fragment, and a later `01.2629A` fragment.
2. A diagnostics/resource fragment contains `sirius_`, memory-usage text and filesystem/USB fragments.
3. A manufacturer/service-mode fragment contains `MFG_MODE_SET`, `Service`, `Mod`, `SOFT` and `CNX/` fragments.

The same CROM image contains multiple `Provider.cpp`, `Service.cpp`, `/cdm/supply/v1`, `/cdm/system/v1`, `PE SERVICE DATA`, and `ServiceInfo`/`RTP`/subscription/counter fragments. Several of these are also inside local branch-skipped regions. They are source/resource/diagnostic text fragments, not recovered runtime dispatcher methods or pointer registrations.

There is no exact `siriusInstance` string or `rtp_manager` string in this section. Raw little-endian scans also do not find the specific alert-list selector `0x0061862B`, alert-list field `0xC136E704`, setter `0xE0277130`, RTP service ID `0x0001229F`, RTP binder `0xE07BCF10`, or RTP helper `0xE07BDFA8`. These are raw byte-scan negatives only; they do not prove semantic absence if values are encoded, relocated, or supplied indirectly.

## Limits

- The full `.cromsrtext` image still has no complete entry-point map, mapping-symbol table, or global code/data boundary map.
- A forward branch proves that its individual skipped bytes are not executed along that branch path. It does not prove that no other branch or entry point reaches any byte within the interval.
- Some strings are interrupted by non-ASCII bytes. Descriptions preserve visible fragments rather than inventing complete normalized path names.
- The CROM provider/service vocabulary does not identify the caller of the Part 22 alert-list setter or the concrete pointer passed in `r3`.
- No causal connection from these strings to RTP print blocking or the PE blocked-state writer is established.

## Reproduction

```bash
python extract_crom_section.py /path/to/fhx_secure_payload_rebuilt.bin /tmp/CROM_SR_TEXT_SECTION.bin
python verify_part22_step8.py
python build_step8_inventory.py
```

`verify_part22_step8.py` checks section size/hash, all three `sirius` occurrences, all 13 selected branch encodings/targets/interval-containment facts, exact source-term counts, and raw literal absence for the key addresses/selectors. It does not rely on text extracted from the findings document.

