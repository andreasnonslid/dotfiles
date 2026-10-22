use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct State;

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _: BTreeMap<String, String>) {
        // pane would otherwise split the focused tab; hide before it is useful
        hide_self();
        request_permission(&[PermissionType::ChangeApplicationState]);
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        // "<1-based tab index>\t<new name>"
        if let Some(payload) = pipe_message.payload.as_deref() {
            if let Some((pos, name)) = payload.split_once('\t') {
                if let Ok(pos) = pos.parse() {
                    rename_tab(pos, name);
                }
            }
        }
        unblock_cli_pipe_input(&pipe_message.name);
        false
    }
}
