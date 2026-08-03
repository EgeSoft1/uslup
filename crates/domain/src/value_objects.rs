// Domain değer nesneleri (Value Objects)

use serde::{Serialize, Deserialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Hash)]
pub struct PhoneNumber(pub String);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Hash)]
pub struct MessageId(pub Uuid);
